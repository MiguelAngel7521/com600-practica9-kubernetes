# Práctica 9 · Kubernetes, Helm y GitOps

Rodriguez Vela Miguel Angel · COM-600 · Parte 1.

Este repositorio contiene los manifiestos y el chart usados en los ocho laboratorios de la Hoja de Evidencias. La Parte 2 se entrega por separado sobre el proyecto integrador y no forma parte de esta hoja.

## Herramientas y clúster

Versiones utilizadas: Docker 29.8.2, k3d 5.9.0, kubectl 1.33.6, Kubernetes/k3s 1.33.6+k3s1, Helm 3.19.0 y Argo CD 3.5.6. Instalar Docker, k3d, kubectl y Helm desde sus sitios oficiales. Docker debe estar iniciado.

```bash
git clone https://github.com/MiguelAngel7521/com600-practica9-kubernetes.git
cd com600-practica9-kubernetes
mkdir -p .local
k3d cluster create com600 --agents 2 --image rancher/k3s:v1.33.6-k3s1 \
  --api-port 127.0.0.1:16443 -p '127.0.0.1:18080:80@loadbalancer' \
  --kubeconfig-update-default=false --kubeconfig-switch-context=false
k3d kubeconfig get com600 > .local/kubeconfig
chmod 600 .local/kubeconfig
source entorno.sh
kubectl get nodes
```

Se usa 18080 porque 8080 estaba ocupado por otra práctica; el túnel diagnóstico usa 18081 porque 8081 también estaba ocupado. El Ingress mantiene el host `tareas.localhost`.

## Imágenes

Los laboratorios iniciales usan exactamente la imagen publicada en la Práctica 8:
`ghcr.io/miguelangel7521/com600-practico8:438ae59c65fa005841fc44db8522ac356ad68f01`.

Esa API tiene `/tareas`, pero no `/salud`. El Dockerfile de `app/` extiende esa misma imagen y agrega `/salud` y `/version`, conservando la API original. GitHub Actions publica dos etiquetas fijas: `ghcr.io/miguelangel7521/com600-practica9-kubernetes:1.0.0` y `:2.0.0`. El endpoint de salud informa la versión para comprobar el cambio real durante el rollout. Estas sondas corresponden al laboratorio guiado: no se afirma que prueben una dependencia externa.

## Despliegue declarativo

El Secret se crea fuera de Git; el único valor utilizado es ficticio y está indicado en el enunciado:

```bash
kubectl create secret generic tareas-secret --from-literal=APP_CLAVE_API=clave-de-laboratorio-2026
kubectl apply -f k8s/
kubectl rollout status deployment/tareas
curl -H 'Host: tareas.localhost' http://localhost:18080/salud
# Navegador: http://tareas.localhost:18080/tareas
```

El proceso conserva las tareas en memoria por réplica, igual que en la Práctica 8. No es un almacén persistente ni compartido. La estrategia usa `maxUnavailable: 0`, `maxSurge: 1`, sondas de readiness y liveness, ocho segundos de disponibilidad mínima y cinco segundos de preStop para el drenaje de conexiones.

## Helm

En esta fase Argo CD todavía no debe administrar `tareas`. Revisar el contexto antes de retirar los recursos del laboratorio anterior.

```bash
kubectl config current-context
kubectl delete -f k8s/
helm lint chart
helm template tareas ./chart
helm install tareas ./chart --wait
helm upgrade tareas ./chart --set replicaCount=3 --wait
helm rollback tareas 1 --wait
helm install tareas-prod ./chart -f chart/values-prod.yaml --wait
helm history tareas
helm list
```

Las dos instalaciones de la Parte 1 conviven en `default`, con nombres y hosts diferentes, como propone el laboratorio. El chart incluye Deployment, Service, Ingress y ConfigMap; el Secret existente se referencia, nunca se incorpora a la plantilla.

## GitOps

Retirar Helm **antes** de entregar los recursos a Argo CD. El orden mostrado en el enunciado permite un conflicto de propietarios si se crea antes la Application.

```bash
helm uninstall tareas tareas-prod
kubectl create namespace argocd
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.6/manifests/install.yaml
kubectl wait -n argocd --for=condition=Available deployments --all --timeout=300s
kubectl apply -f argocd/application.yaml
kubectl -n argocd port-forward svc/argocd-server 8090:443
```

Abrir `https://localhost:8090`, aceptar el certificado local e iniciar sesión como `admin`. Obtener la contraseña en otra terminal; no guardarla en capturas ni subirla a Git:

```bash
source entorno.sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

La aplicación `tareas` se sincroniza automáticamente desde `k8s/` de este repositorio, con `prune` y `selfHeal`. Para trabajar en una copia propia, cambiar `repoURL` por el repositorio público de esa copia. Modificar `replicas` en `k8s/deployment.yaml`, hacer commit y push y esperar la reconciliación; no ejecutar `kubectl apply -f k8s/` en esta etapa. Refresh solo solicita volver a leer Git.

Para demostrar la reparación, ejecutar `kubectl scale deployment tareas --replicas=7`: Argo CD detecta OutOfSync y vuelve al número declarado en Git. El Secret de laboratorio se conserva fuera del directorio gestionado; la solución de secretos cifrados de la Parte 2 no se presenta como realizada aquí.

Para hacer legible la transición en la captura 20 se configuró `controller.self.heal.timeout.seconds: "30"` en `argocd-cmd-params-cm` y se reinició su StatefulSet. `selfHeal` permaneció activo. Se sincronizó primero una anotación de demostración mediante Git y luego se provocó el cambio a siete réplicas; tras el intervalo, el controlador las devolvió automáticamente a tres. Este ajuste de observación no es necesario para desplegar la aplicación.

## Fuentes de consulta

- [Kubernetes: Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [k3d: kubeconfig](https://k3d.io/v5.8.3/usage/kubeconfig/)
- [Helm: charts](https://helm.sh/docs/topics/charts/)
- [Argo CD: instalación](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/)
- [Argo CD: sincronización automática](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
