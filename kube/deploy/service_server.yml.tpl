---
apiVersion: v1
kind: Service
metadata:
  name: $DOMAIN-server-$ENV
spec:
  selector:
    app: $DOMAIN-server
    domain: $DOMAIN
    env: $ENV
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000 
    nodePort: $NODE_PORT 
  type: NodePort
...
