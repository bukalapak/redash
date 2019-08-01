IMAGE_REPOSITORY=registry.bukalapak.io/coredata/redash-scalable
IMAGE_VERSION:=3.17

FLOWER_IMAGE_REPOSITORY=registry.bukalapak.io/coredata/redash-scalable/redash-flower
FLOWER_IMAGE_VERSION:=0.9.2.1
TELEGRAM_BOT_IMAGE:=registry.bukalapak.io/coredata/redash-scalable/alert-telegram-bot
TELEGRAM_BOT_VERSION:=1

SERVER_REPLICAS=5
WORKER_REPLICAS=10

ifneq ($(ENV),production)
DOMAIN:=dev-redash
NODE_PORT:= 35999
FLOWER_NODE_PORT:=35998
NODE_SELECTOR:=sandbox
ENV:=beta
SERVER_REPLICAS=1
WORKER_REPLICAS=1
else
NODE_SELECTOR:=dc3_coredata_01
ifndef DOMAIN
$(error DOMAIN is not set)
else ifeq ($(DOMAIN),redash)
NODE_PORT:=35000
FLOWER_NODE_PORT:=35020
else ifeq ($(DOMAIN),cs-redash)
NODE_PORT:=35001
FLOWER_NODE_PORT:=35021
else ifeq ($(DOMAIN),dg-redash)
NODE_PORT:=35002
FLOWER_NODE_PORT:=35022
else ifeq ($(DOMAIN),rev-redash)
NODE_PORT:=35003
FLOWER_NODE_PORT:=35023
else ifeq ($(DOMAIN),supply-redash)
NODE_PORT:=35004
FLOWER_NODE_PORT:=35024
else ifeq ($(DOMAIN),trust-redash)
NODE_PORT:=35005
FLOWER_NODE_PORT:=35025
else ifeq ($(DOMAIN),adhoc-redash)
NODE_PORT:=35006
FLOWER_NODE_PORT:=35026
SERVER_REPLICAS=1
WORKER_REPLICAS=1
else
$(error DOMAIN is invalid)
endif
endif

prepare:
	mkdir -p tmp/$(DOMAIN)
	sed "\
		s~\$$IMAGE_REPOSITORY~$(IMAGE_REPOSITORY)~g;\
		s~\$$IMAGE_VERSION~$(IMAGE_VERSION)~g;\
		s~\$$DOMAIN~$(DOMAIN)~g;\
		s~\$$ENV~$(ENV)~g;\
		s~\$$NODE_SELECTOR~$(NODE_SELECTOR)~g"\
		deploy/deployment_redis.yml.tpl > tmp/$(DOMAIN)/deployment_redis.yml
	sed "\
		s~\$$IMAGE_REPOSITORY~$(IMAGE_REPOSITORY)~g;\
		s~\$$IMAGE_VERSION~$(IMAGE_VERSION)~g;\
		s~\$$DOMAIN~$(DOMAIN)~g;\
		s~\$$ENV~$(ENV)~g;\
		s~\$$NODE_SELECTOR~$(NODE_SELECTOR)~g;\
		s~\$$WORKER_REPLICAS~$(WORKER_REPLICAS)~g"\
		deploy/deployment_worker.yml.tpl > tmp/$(DOMAIN)/deployment_worker.yml
	sed "\
		s~\$$IMAGE_REPOSITORY~$(IMAGE_REPOSITORY)~g;\
		s~\$$IMAGE_VERSION~$(IMAGE_VERSION)~g;\
		s~\$$DOMAIN~$(DOMAIN)~g;\
		s~\$$ENV~$(ENV)~g;\
		s~\$$NODE_SELECTOR~$(NODE_SELECTOR)~g"\
		deploy/deployment_beat.yml.tpl > tmp/$(DOMAIN)/deployment_beat.yml
	sed "\
		s~\$$IMAGE_REPOSITORY~$(IMAGE_REPOSITORY)~g;\
		s~\$$IMAGE_VERSION~$(IMAGE_VERSION)~g;\
		s~\$$DOMAIN~$(DOMAIN)~g;\
		s~\$$ENV~$(ENV)~g;\
		s~\$$NODE_SELECTOR~$(NODE_SELECTOR)~g;\
		s~\$$SERVER_REPLICAS~$(SERVER_REPLICAS)~g"\
		deploy/deployment_server.yml.tpl > tmp/$(DOMAIN)/deployment_server.yml
	sed "\
		s~\$$NODE_PORT~$(NODE_PORT)~g;\
		s~\$$DOMAIN~$(DOMAIN)~g;\
		s~\$$ENV~$(ENV)~g"\
		deploy/service_redis.yml.tpl > tmp/$(DOMAIN)/service_redis.yml
	sed "\
		s~\$$NODE_PORT~$(NODE_PORT)~g;\
		s~\$$DOMAIN~$(DOMAIN)~g;\
		s~\$$ENV~$(ENV)~g"\
		deploy/service_server.yml.tpl > tmp/$(DOMAIN)/service_server.yml

build:
	docker build -t $(IMAGE_REPOSITORY):$(IMAGE_VERSION) .

push:
	docker push $(IMAGE_REPOSITORY):$(IMAGE_VERSION)

docker-all: build push

kube-create: prepare
	kubectl create -f tmp/$(DOMAIN)/deployment_redis.yml
	kubectl create -f tmp/$(DOMAIN)/service_redis.yml
	sleep 3 
	kubectl create -f tmp/$(DOMAIN)/deployment_worker.yml
	kubectl create -f tmp/$(DOMAIN)/deployment_beat.yml    
	kubectl create -f tmp/$(DOMAIN)/deployment_server.yml  
	kubectl create -f tmp/$(DOMAIN)/service_server.yml
	kubectl create -f tmp/$(DOMAIN)/deployment_flower.yml
	kubectl create -f tmp/$(DOMAIN)/service_flower.yml

kube-delete:
	kubectl delete deployment $(DOMAIN)-scalable-server-$(ENV)
	kubectl delete deployment $(DOMAIN)-scalable-flower-$(ENV)
	kubectl delete deployment $(DOMAIN)-scalable-beat-$(ENV)
	kubectl delete deployment $(DOMAIN)-scalable-worker-$(ENV)
	kubectl delete deployment redis-$(DOMAIN)-scalable
	kubectl delete service $(DOMAIN)-scalable-server-$(ENV)
	kubectl delete service $(DOMAIN)-scalable-flower-$(ENV)
	kubectl delete service redis-$(DOMAIN)-scalable

kube-replace: prepare
	kubectl replace -f tmp/$(DOMAIN)/deployment_redis.yml   
	kubectl replace -f tmp/$(DOMAIN)/deployment_worker.yml  
	kubectl replace -f tmp/$(DOMAIN)/deployment_beat.yml    
	kubectl replace -f tmp/$(DOMAIN)/deployment_server.yml  
	kubectl replace -f tmp/$(DOMAIN)/deployment_flower.yml

deploy: kube-replace

flush-redis-commands:
	kubectl scale --replicas=0 deployment $(DOMAIN)-scalable-beat-$(ENV)
	kubectl scale --replicas=0 deployment $(DOMAIN)-scalable-worker-$(ENV)
	sleep 5
	kubectl exec -it $$(kubectl get pods -l app=redis-$(DOMAIN)-scalable | awk 'NR>1{ print $$1 }') -- redis-cli flushall
	kubectl scale --replicas=1 deployment $(DOMAIN)-scalable-beat-$(ENV)
	kubectl scale --replicas=10 deployment $(DOMAIN)-scalable-worker-$(ENV)
	kubectl delete pods $$(kubectl get pods -l domain=$(DOMAIN)-scalable | grep flower | awk '{ print $$1 }')
