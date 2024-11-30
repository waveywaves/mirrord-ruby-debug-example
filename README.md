# mirrord-ruby-debug-example

```
bundle install
kubectl apply -f kube
mirrord exec -f mirrord.json ruby -- app.rb -o 0.0.0.0 -p 4567
```