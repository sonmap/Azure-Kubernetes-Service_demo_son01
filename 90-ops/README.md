# 90-ops

운영 확인용 명령어입니다.

## kubeconfig 가져오기

```bash
az aks get-credentials \
  -g rg-aks-store-demo-dev-krc \
  -n aks-store-demo-dev-krc \
  --overwrite-existing
```

## 전체 확인

```bash
kubectl get all -n pets
kubectl get pod -n pets -o wide
kubectl get svc -n pets
```

## 서비스 로그

```bash
kubectl logs -n pets deploy/order-service
kubectl logs -n pets deploy/makeline-service
kubectl logs -n pets deploy/product-service
kubectl logs -n pets deploy/store-front
kubectl logs -n pets deploy/store-admin
```

## Public IP 확인

```bash
kubectl get svc store-front -n pets
kubectl get svc store-admin -n pets
```

## 장애 확인

```bash
kubectl describe pod -n pets <POD_NAME>
kubectl get events -n pets --sort-by='.lastTimestamp'
```
