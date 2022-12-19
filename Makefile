.PHONY: test
test:
	@echo "\n🛠️  Running unit tests..."
	go test ./...

.PHONY: build
build:
	@echo "\n🔧  Building Go binaries..."
	GOOS=darwin GOARCH=amd64 go build -o bin/admission-webhook-darwin-amd64 .
	GOOS=linux GOARCH=amd64 go build -o bin/admission-webhook-linux-amd64 .

.PHONY: docker-build
docker-build:
	@echo "\n📦 Building envd-server-pod-webhook Docker image..."
	docker buildx build -t envd-server-pod-webhook:latest .

# From this point `kind` is required
.PHONY: cluster
cluster:
	@echo "\n🔧 Creating Kubernetes cluster..."
	kind create cluster --config dev/manifests/kind/kind.cluster.yaml

.PHONY: delete-cluster
delete-cluster:
	@echo "\n♻️  Deleting Kubernetes cluster..."
	kind delete cluster

.PHONY: push
push:
	@echo "\n📦 Pushing admission-webhook image into Kind's Docker daemon..."
	kind load docker-image envd-server-pod-webhook:latest

.PHONY: deploy-config
deploy-config:
	@echo "\n⚙️  Applying cluster config..."
	kubectl apply -f dev/manifests/cluster-config/

.PHONY: delete-config
delete-config:
	@echo "\n♻️  Deleting Kubernetes cluster config..."
	kubectl delete -f dev/manifests/cluster-config/

.PHONY: deploy
deploy: push delete deploy-config
	@echo "\n🚀 Deploying envd-server-pod-webhook..."
	kubectl apply -f dev/manifests/webhook/

.PHONY: delete
delete:
	@echo "\n♻️  Deleting envd-server-pod-webhook deployment if existing..."
	kubectl delete -f dev/manifests/webhook/ || true

.PHONY: pod
pod:
	@echo "\n🚀 Deploying test pod..."
	kubectl apply -f dev/manifests/pods/lifespan-seven.pod.yaml

.PHONY: delete-pod
delete-pod:
	@echo "\n♻️ Deleting test pod..."
	kubectl delete -f dev/manifests/pods/lifespan-seven.pod.yaml

.PHONY: bad-pod
bad-pod:
	@echo "\n🚀 Deploying \"bad\" pod..."
	kubectl apply -f dev/manifests/pods/bad-name.pod.yaml

.PHONY: delete-bad-pod
delete-bad-pod:
	@echo "\n🚀 Deleting \"bad\" pod..."
	kubectl delete -f dev/manifests/pods/bad-name.pod.yaml

.PHONY: taint
taint:
	@echo "\n🎨 Taining Kubernetes node.."
	kubectl taint nodes kind-control-plane "acme.com/lifespan-remaining"=4:NoSchedule

.PHONY: logs
logs:
	@echo "\n🔍 Streaming envd-server-pod-webhook logs..."
	kubectl logs -l app=envd-server-pod-webhook -f

.PHONY: delete-all
delete-all: delete delete-config delete-pod delete-bad-pod
