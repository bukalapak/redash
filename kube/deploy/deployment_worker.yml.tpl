---
apiVersion: extensions/v1beta1 
kind: Deployment
metadata:
  name: $DOMAIN-worker-$ENV
spec:
  selector:
    matchLabels:
      app: $DOMAIN-worker 
  replicas: $WORKER_REPLICAS 
  revisionHistoryLimit: 0
  template:
    metadata:
      labels:
        app: $DOMAIN-worker 
        domain: $DOMAIN
        superdomain: redash
        env: $ENV
    spec:
      imagePullSecrets:
      - name: blregistry
      volumes:
      - name: worker-tmp-volume
        emptyDir:
          medium: Memory
      nodeSelector:
        env: $NODE_SELECTOR
      containers:
      - name: consul
        image: consul:0.7.3
        ports:
          - containerPort: 8300
          - containerPort: 8301
          - containerPort: 8302
          - containerPort: 8400
          - containerPort: 8500
          - containerPort: 8600
        env:
          - name: CONSUL_LOCAL_CONFIG
            value: "{\"leave_on_terminate\": true}"
          - name: CONSUL1
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: node1
          - name: CONSUL2
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: node2
          - name: CONSUL3
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: node3
          - name: CONSUL_ENCRYPT
            valueFrom:
              configMapKeyRef:
                name: consul-config
                key: encrypt
        command:
          - consul
          - agent
          - -datacenter=biznet
          - -data-dir=/tmp/consul
          - -join=$(CONSUL1)
          - -join=$(CONSUL2)
          - -join=$(CONSUL3)
          - -encrypt=$(CONSUL_ENCRYPT)
      - name: redash
        image: $IMAGE_REPOSITORY:$IMAGE_VERSION
        imagePullPolicy: Always
        resources:
          requests:
            memory: "3Gi"
            cpu: "2000m"
          limits:
            memory: "4Gi"
            cpu: "4000m"
        command: 
          - envconsul 
          - -prefix=redash/shared
          - -prefix=redash/$DOMAIN
          - -prefix=redash/$DOMAIN-scalable 
          - /home/redash/.local/bin/celery
          - worker
          - --app=redash.worker
          - --autoscale=30,10
          - -Qqueries,scheduled_queries,celery
          - --maxtasksperchild=5
          - -Ofair
          - -lINFO
        lifecycle:
          preStop:
            exec:
              command: ["pkill", "-SIGTERM", "-f", "celery"]
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - |
              envconsul -prefix=redash/shared -prefix=redash/$DOMAIN -prefix=redash/$DOMAIN-scalable /home/redash/.local/bin/celery --app=redash.worker inspect ping -d celery@$HOSTNAME
          initialDelaySeconds: 30
          periodSeconds: 5
        volumeMounts:
        - mountPath: /tmp
          name: worker-tmp-volume
...
