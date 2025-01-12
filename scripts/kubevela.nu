#!/usr/bin/env nu

def "main apply kubevela" [
    host: string,
    --ingress_class = "nginx"
] {

    vela install

    (
        vela addon enable velaux
            domain=$host
            gatewayDriver=$ingress_class
    )

    start $"http://($host)"

}