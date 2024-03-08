resource "kubernetes_ingress_v1" "voting-ingress" {
  metadata {
    name      = "voting-app"
    namespace = "voting-app"
    labels = {
      name = "voting-service"
    }
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
    }
  }

  spec {
    rule {
      host = "voting-app.awspro.com.ng"
      http {
        path {
          backend {
            service{
              name = "voting-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_ingress_v1" "result-ingress" {
  metadata {
    name      = "result-app"
    namespace = "voting-app"
    labels = {
      name = "voting-service"
    }
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
    }
  }

  spec {
    rule {
      host = "result.awspro.com.ng"
      http {
        path {
          backend {
            service{
            name = "result-service"
            port {
              number = 80
            }
            }
          }
        }
      }
    }
  }
}