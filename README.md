# Azure Kubernetes Service Demo Son01

> AKS 기반 **Contoso Pet Store / AKS Store Demo**를 Terraform으로 분리 배포하는 학습용 프로젝트입니다.  
> Azure 인프라 생성부터 AKS 클러스터 구성, Kubernetes 애플리케이션 배포, 외부 LoadBalancer 접속, 장애 조치 및 삭제까지 전체 과정을 단계별 Terraform Stack으로 구성합니다.

---

## 1. 프로젝트 개요

이 저장소는 Azure Kubernetes Service(AKS)를 사용하여 마이크로서비스 기반 샘플 애플리케이션을 배포하는 데모입니다.

기본 애플리케이션은 다음 구성 요소로 이루어집니다.

- `store-front`: 사용자용 웹 프론트엔드
- `store-admin`: 관리자용 웹 포털
- `product-service`: 상품 서비스
- `order-service`: 주문 서비스
- `makeline-service`: 주문 처리 서비스
- `mongodb`: 주문 및 애플리케이션 데이터 저장소
- `rabbitmq`: 메시지 큐
- `virtual-customer`: 가상 고객 트래픽 생성기
- `virtual-worker`: 가상 작업자 시뮬레이터
- `ai-service`: 선택형 AI 서비스

이 프로젝트의 목표는 단순히 AKS 앱을 올리는 것이 아니라, **Azure 인프라와 Kubernetes 리소스를 Terraform으로 그룹화하여 재사용 가능한 구조로 만드는 것**입니다.

---

## 2. 주요 목표
![Uploading ChatGPT Image Jun 23, 2026, 11_37_36 PM.png…]()

| 구분 | 내용 |
|---|---|
| IaC | Azure Resource Group, VNet, Subnet, NSG, AKS, Kubernetes 리소스를 Terraform으로 생성 |
| 그룹 분리 | 인프라와 애플리케이션을 `00`, `10`, `20` 형식의 Stack으로 분리 |
| AKS 학습 | AKS NodePool, LoadBalancer, Service, Deployment, StatefulSet, Namespace 학습 |
| 마이크로서비스 | Frontend, Backend, Data Service, Simulator를 분리 배포 |
| 장애 분석 | MongoDB probe 오류, TLS 시간 오류, NSG 차단, LoadBalancer timeout 문제를 실습 |
| 자동화 | 수동 `az network nsg rule create`, `kubectl apply` 의존도를 낮추고 Terraform 중심으로 구성 |
| 삭제 자동화 | Terraform destroy 순서를 명확히 하여 비용 누수 방지 |

---

## 3. 전체 아키텍처

```text
Internet / Browser
        |
        | HTTP 80
        v
+-----------------------------+
| Azure Public Load Balancer  |
| store-front / store-admin   |
+-----------------------------+
        |
        | NodePort
        | store-front : 30544 예시
        | store-admin : 31792 예시
        v
+-----------------------------------------------------+
| Azure Kubernetes Service                            |
| aks-store-demo-dev-krc                              |
|                                                     |
|  Namespace: pets                                    |
|                                                     |
|  +----------------+       +----------------+        |
|  | store-front    |       | store-admin    |        |
|  | Vue + Nginx    |       | Vue + Nginx    |        |
|  | Port 8080      |       | Port 8081      |        |
|  +-------+--------+       +--------+-------+        |
|          |                         |                |
|          v                         v                |
|  +----------------+       +----------------+        |
|  | order-service  |       | product-service|        |
|  | Port 3000      |       | Port 3002      |        |
|  +-------+--------+       +----------------+        |
|          |                                          |
|          v                                          |
|  +----------------+                                  |
|  | rabbitmq       |                                  |
|  | 5672 / 15672   |                                  |
|  +-------+--------+                                  |
|          |                                          |
|          v                                          |
|  +----------------+                                  |
|  | makeline       |                                  |
|  | Port 3001      |                                  |
|  +-------+--------+                                  |
|          |                                          |
|          v                                          |
|  +----------------+                                  |
|  | mongodb        |                                  |
|  | Port 27017     |                                  |
|  +----------------+                                  |
|                                                     |
|  +----------------+       +----------------+        |
|  | virtual        |       | virtual        |        |
|  | customer       |       | worker         |        |
|  +----------------+       +----------------+        |
+-----------------------------------------------------+
```

---

## 4. Azure 인프라 구조

```text
Azure Subscription
|
+-- Resource Group
|   name: rg-aks-store-demo-dev-krc
|   location: koreacentral
|
+-- Log Analytics Workspace
|   용도: AKS Container Insights / 로그 확인
|
+-- Virtual Network
|   name: vnet-aks-store-demo-dev-krc
|   address space: 10.40.0.0/16
|
+-- Subnet
|   name: snet-aks
|   address prefix: 10.40.1.0/24
|
+-- Network Security Group
|   name: nsg-snet-aks-store-demo-dev-krc
|   주요 허용:
|     - AzureLoadBalancer Probe
|     - HTTP 80
|     - AKS NodePort 테스트 범위 30000-32767
|
+-- AKS Cluster
|   name: aks-store-demo-dev-krc
|   node pool: system
|   node count: 1
|   network: Azure CNI Overlay
|
+-- Kubernetes Services
    - store-front LoadBalancer
    - store-admin LoadBalancer
    - backend/data service ClusterIP
```

---

## 5. Terraform Stack 구성

이 프로젝트는 한 번에 모든 것을 배포하지 않고, 다음과 같이 그룹별로 나누어 배포합니다.

```text
.
├── 00-foundation
│   ├── Resource Group
│   └── Log Analytics Workspace
│
├── 10-network
│   ├── Virtual Network
│   ├── AKS Subnet
│   ├── Network Security Group
│   └── AKS LoadBalancer / NodePort 허용 Rule
│
├── 20-aks
│   ├── AKS Cluster
│   ├── System Node Pool
│   └── AKS Monitoring 연결
│
├── 30-k8s-base
│   └── Kubernetes Namespace: pets
│
├── 40-data-services
│   ├── MongoDB StatefulSet / Service
│   └── RabbitMQ StatefulSet / Service / ConfigMap / Secret
│
├── 50-backend-services
│   ├── order-service
│   ├── product-service
│   └── makeline-service
│
├── 60-frontends
│   ├── store-front Deployment / LoadBalancer Service
│   └── store-admin Deployment / LoadBalancer Service
│
├── 70-simulators
│   ├── virtual-customer
│   └── virtual-worker
│
├── 80-ai-optional
│   └── 선택형 ai-service
│
├── 90-ops
│   └── 운영 및 확인 명령어
│
└── scripts
    ├── 01-apply-all.sh
    ├── 02-kubectl-check.sh
    └── 99-destroy-all.sh
```

---

## 6. 배포 순서

각 Stack은 이전 Stack의 Terraform state output을 참조합니다.  
따라서 반드시 아래 순서대로 배포해야 합니다.

```text
1. 00-foundation
2. 10-network
3. 20-aks
4. 30-k8s-base
5. 40-data-services
6. 50-backend-services
7. 60-frontends
8. 70-simulators
9. 80-ai-optional
```

기본 테스트에서는 `80-ai-optional`은 생략할 수 있습니다.

---

## 7. 사전 준비

### 7.1 필수 도구

| 도구 | 용도 |
|---|---|
| Azure CLI | Azure 로그인 및 AKS kubeconfig 획득 |
| Terraform | Azure 및 Kubernetes 리소스 배포 |
| kubectl | AKS 상태 확인 |
| Git | 저장소 clone |
| Bash | 자동화 스크립트 실행 |

### 7.2 Azure 로그인

```bash
az login
az account show -o table
```

구독 지정:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 7.3 시간 동기화 확인

AKS API Server 인증서 검증은 로컬 OS 시간이 맞아야 정상 동작합니다.

```bash
date
date -u
timedatectl
```

Linux 시간 동기화 예시:

```bash
sudo timedatectl set-timezone Asia/Seoul
sudo systemctl enable --now chronyd
sudo chronyc makestep
sudo hwclock --systohc
```

---

## 8. 전체 배포 방법

### 8.1 저장소 clone

```bash
git clone https://github.com/sonmap/Azure-Kubernetes-Service_demo_son01.git
cd Azure-Kubernetes-Service_demo_son01
```

### 8.2 전체 자동 배포

```bash
cd scripts
bash 01-apply-all.sh
```

### 8.3 수동 단계별 배포

```bash
cd 00-foundation
terraform init
terraform plan
terraform apply

cd ../10-network
terraform init
terraform plan
terraform apply

cd ../20-aks
terraform init
terraform plan
terraform apply

cd ../30-k8s-base
terraform init
terraform plan
terraform apply

cd ../40-data-services
terraform init
terraform plan
terraform apply

cd ../50-backend-services
terraform init
terraform plan
terraform apply

cd ../60-frontends
terraform init
terraform plan
terraform apply

cd ../70-simulators
terraform init
terraform plan
terraform apply
```

---

## 9. 접속 URL 확인

`60-frontends` Stack은 LoadBalancer External IP를 output으로 제공합니다.

```bash
cd 60-frontends
terraform output
```

예시:

```text
store_front_url = "http://20.x.x.x"
store_admin_url = "http://20.x.x.x"
```

브라우저 접속:

```text
http://<store-front-external-ip>
http://<store-admin-external-ip>
```

---

## 10. Kubernetes 상태 확인

```bash
kubectl get ns
kubectl get all -n pets
kubectl get pod -n pets -o wide
kubectl get svc -n pets
kubectl get endpoints -n pets
```

정상 예시:

```text
mongodb-0                           1/1   Running
rabbitmq-0                          1/1   Running
order-service-xxxxx                 1/1   Running
product-service-xxxxx               1/1   Running
makeline-service-xxxxx              1/1   Running
store-front-xxxxx                   1/1   Running
store-admin-xxxxx                   1/1   Running
virtual-customer-xxxxx              1/1   Running
virtual-worker-xxxxx                1/1   Running
```

Service 정상 예시:

```text
store-front   LoadBalancer   10.x.x.x   20.x.x.x   80:30xxx/TCP
store-admin   LoadBalancer   10.x.x.x   20.x.x.x   80:31xxx/TCP
```

---

## 11. 내부 통신 테스트

외부 접속이 안 될 때는 먼저 AKS 내부에서 서비스가 정상인지 확인해야 합니다.

```bash
kubectl run curl-test -n pets --rm -it \
  --image=curlimages/curl:8.10.1 \
  --restart=Never -- sh
```

컨테이너 안에서 실행:

```bash
curl -v http://store-front:80/
curl -v http://store-admin:80/
exit
```

정상 응답:

```text
HTTP/1.1 200 OK
Server: nginx
```

내부 통신이 성공하면 앱과 Kubernetes Service는 정상입니다.  
이때 외부 접속이 안 되면 Azure LoadBalancer, NSG, NodePort 경로를 확인해야 합니다.

---

## 12. 외부 접속 흐름

```text
Browser
  |
  | HTTP 80
  v
Public IP
  |
  v
Azure Load Balancer
  |
  | NodePort
  | 예: 30544 / 31792
  v
AKS Node
  |
  v
Kubernetes Service
  |
  v
Pod
```

이 프로젝트에서는 Terraform이 `10-network`에서 NSG Rule을 생성하여 수동 명령 없이 접근 가능하도록 구성합니다.

주요 NSG Rule:

```text
tf-allow-aks-store-public-lb-http
tf-allow-azure-load-balancer-probe
tf-allow-aks-nodeport-test
```

---

## 13. 주요 Terraform 설계 포인트

### 13.1 Stack 분리

각 영역을 독립적인 Terraform 디렉터리로 나누었습니다.

장점:

- 장애 발생 시 문제 범위가 명확함
- 네트워크만 재적용 가능
- AKS만 재생성 가능
- Kubernetes 앱만 재배포 가능
- 운영 환경에서 변경 영향도 관리가 쉬움

### 13.2 Remote State 참조

후속 Stack은 이전 Stack의 output을 참조합니다.

예:

```text
20-aks        -> 00-foundation, 10-network output 참조
30-k8s-base   -> 20-aks kubeconfig 참조
40-data       -> 30-k8s-base namespace output 참조
50-backend    -> 40-data service 이름 참조
60-frontends  -> 50-backend service 참조
```

현재 학습용 구성은 local state 기반입니다.  
실무에서는 Azure Storage Account backend를 사용하는 것이 좋습니다.

---

## 14. MongoDB StatefulSet 구성

MongoDB는 StatefulSet으로 배포합니다.

초기 테스트 중 다음 문제가 발생했습니다.

```text
StatefulSet pets/mongodb is not finished rolling out
mongodb-0 CrashLoopBackOff
liveness probe failed
command timed out: mongo --eval db.runCommand('ping').ok
```

원인:

```text
CPU limit 25m로 너무 낮음
mongo --eval 기반 liveness/readiness probe가 timeout
MongoDB는 정상 기동했으나 kubelet이 probe 실패로 강제 종료
```

해결:

```text
CPU request: 100m
CPU limit  : 500m
Readiness/Liveness probe: exec 방식에서 tcp_socket 방식으로 변경
startup_probe 추가
wait_for_rollout = false 적용
```

---

## 15. NSG / LoadBalancer 접속 문제 해결

테스트 중 다음 현상이 있었습니다.

```text
store-front LoadBalancer EXTERNAL-IP 생성 완료
store-admin LoadBalancer EXTERNAL-IP 생성 완료
Pod 1/1 Running
Endpoint 정상
AKS 내부 curl 200 OK
외부 브라우저 접속 timeout
```

분석 결과:

```text
앱 문제 아님
Kubernetes Service 문제 아님
Endpoint 문제 아님
Azure LoadBalancer -> AKS NodePort 경로의 NSG 차단 가능성 높음
```

Terraform 수정 내용:

```text
10-network/main.tf에 NSG inbound rule 추가
Internet -> HTTP 80 허용
AzureLoadBalancer -> probe 허용
Internet -> NodePort 30000-32767 테스트 허용
```

---

## 16. 주요 명령어 요약

### AKS 인증 정보 가져오기

```bash
az aks get-credentials \
  -g rg-aks-store-demo-dev-krc \
  -n aks-store-demo-dev-krc \
  --overwrite-existing
```

### Pod 확인

```bash
kubectl get pod -n pets -o wide
```

### Service 확인

```bash
kubectl get svc -n pets
```

### Endpoint 확인

```bash
kubectl get endpoints -n pets -o wide
```

### 로그 확인

```bash
kubectl logs -n pets deploy/store-front --tail=100
kubectl logs -n pets deploy/store-admin --tail=100
kubectl logs -n pets deploy/order-service --tail=100
kubectl logs -n pets deploy/product-service --tail=100
kubectl logs -n pets deploy/makeline-service --tail=100
kubectl logs -n pets mongodb-0 --tail=100
kubectl logs -n pets rabbitmq-0 --tail=100
```

---

## 17. 삭제 방법

비용 방지를 위해 테스트 후 반드시 삭제합니다.

### 17.1 전체 자동 삭제

```bash
cd scripts
bash 99-destroy-all.sh
```

### 17.2 수동 삭제 순서

삭제는 생성 순서의 역순으로 수행합니다.

```bash
cd 70-simulators
terraform destroy

cd ../60-frontends
terraform destroy

cd ../50-backend-services
terraform destroy

cd ../40-data-services
terraform destroy

cd ../30-k8s-base
terraform destroy

cd ../20-aks
terraform destroy

cd ../10-network
terraform destroy

cd ../00-foundation
terraform destroy
```

### 17.3 잔여 Resource Group 확인

```bash
az group list -o table | grep aks-store-demo
```

AKS Node Resource Group 확인:

```bash
az group list -o table | grep MC_rg-aks-store-demo
```

필요 시 강제 삭제:

```bash
az group delete \
  -n rg-aks-store-demo-dev-krc \
  --yes --no-wait
```

AKS Node Resource Group이 남아 있으면:

```bash
az group delete \
  -n MC_rg-aks-store-demo-dev-krc_aks-store-demo-dev-krc_koreacentral \
  --yes --no-wait
```

---

## 18. 비용 절감 기준

이 프로젝트는 개인 학습용으로 최소 비용을 고려했습니다.

| 항목 | 기준 |
|---|---|
| AKS Node | 1대 |
| VM Size | Standard_D2s_v3 수준 |
| Azure Firewall | 사용 안 함 |
| Application Gateway | 사용 안 함 |
| Azure Container Registry | 기본 구성에서는 사용 안 함 |
| Cosmos DB | 사용 안 함 |
| Service Bus | 사용 안 함 |
| Azure OpenAI | 선택 기능 |
| MongoDB | AKS 내부 Pod |
| RabbitMQ | AKS 내부 Pod |

운영 환경에서는 MongoDB/RabbitMQ를 AKS 내부에 두기보다는 관리형 서비스로 전환하는 것이 좋습니다.

---

## 19. 운영 환경으로 확장할 때 개선 방향

학습용 구성 이후에는 다음 순서로 확장할 수 있습니다.

```text
Phase 1. 현재 구조
AKS + In-cluster MongoDB + In-cluster RabbitMQ + Public LoadBalancer

Phase 2. 데이터 서비스 관리형 전환
AKS + Azure Cosmos DB + Azure Service Bus

Phase 3. 이미지 관리 강화
Azure Container Registry + Private Image Pull

Phase 4. 보안 강화
Private AKS + Private Endpoint + 제한된 Ingress + Azure Firewall or NVA

Phase 5. 운영 관측성 강화
Azure Monitor + Managed Prometheus + Grafana + Alert

Phase 6. CI/CD
GitHub Actions 또는 Azure DevOps Pipeline 연동

Phase 7. AI 기능
Azure OpenAI + ai-service 연동
```

---

## 20. 실습 중 경험한 주요 오류

### 20.1 TLS 인증서 시간 오류

오류:

```text
tls: failed to verify certificate:
x509: certificate has expired or is not yet valid
current time is before certificate valid time
```

원인:

```text
Terraform 실행 서버의 OS 시간이 실제 시간보다 과거
```

해결:

```bash
sudo timedatectl set-timezone Asia/Seoul
sudo systemctl enable --now chronyd
sudo chronyc makestep
sudo hwclock --systohc
```

### 20.2 MongoDB CrashLoopBackOff

오류:

```text
mongodb-0 CrashLoopBackOff
liveness probe failed
```

해결:

```text
CPU request/limit 상향
exec probe 제거
tcp_socket probe 적용
startup_probe 추가
```

### 20.3 외부 LoadBalancer timeout

오류:

```text
curl http://<EXTERNAL-IP> timeout
브라우저 접속 불가
```

확인:

```bash
kubectl get pod -n pets
kubectl get svc -n pets
kubectl get endpoints -n pets
```

내부 테스트:

```bash
kubectl run curl-test -n pets --rm -it \
  --image=curlimages/curl:8.10.1 \
  --restart=Never -- sh
```

해결:

```text
AKS Subnet NSG에 HTTP 80, AzureLoadBalancer Probe, NodePort 허용 Rule 추가
```

### 20.4 Terraform Provider Identity 오류

오류:

```text
Unexpected Identity Change
Current Identity: null
New Identity: StatefulSet pets/mongodb
```

해결:

```bash
terraform state rm kubernetes_stateful_set_v1.mongodb
terraform import kubernetes_stateful_set_v1.mongodb pets/mongodb
terraform apply
```

---

## 21. 보안 주의사항

이 저장소는 개인 학습 및 테스트용입니다.

운영 환경에서는 다음 사항을 반드시 고려해야 합니다.

- `Internet -> NodePort 30000-32767` 전체 허용 금지
- Public LoadBalancer 대신 Ingress Controller 또는 Application Gateway 사용 검토
- Private AKS 사용 검토
- NSG Source IP를 관리자 IP 또는 사내 NAT IP로 제한
- MongoDB/RabbitMQ Secret 관리 강화
- Terraform state 원격 backend 및 state lock 구성
- Key Vault 연동
- Managed Identity / Workload Identity 적용
- Azure Policy 적용
- 로그 및 알림 구성

---

## 22. 최종 요약

이 프로젝트는 AKS Store Demo를 Terraform 기반으로 재구성한 학습용 프로젝트입니다.

핵심 특징:

- Azure Resource Group, VNet, Subnet, NSG, AKS를 Terraform으로 구성
- Kubernetes Namespace, StatefulSet, Deployment, Service를 Terraform으로 배포
- MongoDB, RabbitMQ, Frontend, Backend, Simulator를 Stack별로 분리
- 외부 LoadBalancer 접속을 Terraform NSG Rule로 자동화
- 수동 `kubectl apply` 없이 Terraform 중심 배포
- 장애 상황을 실제로 분석하고 Terraform 코드에 반영
- 테스트 후 destroy 순서를 명확히 제공하여 비용 누수 방지

---

## 23. 작성자

```text
sonmap
Cloud / Linux / Azure / GCP Engineer
AKS, Terraform, Cloud Architecture 학습 및 실습 프로젝트
```
