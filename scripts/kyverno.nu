#!/usr/bin/env nu

def apply_kyverno [] {

    helm repo add kyverno https://kyverno.github.io/kyverno

    helm repo update

    (
        helm upgrade --install kyverno kyverno/kyverno
            --namespace kyverno --create-namespace
            --wait
    )

}
