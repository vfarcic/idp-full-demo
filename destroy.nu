#!/usr/bin/env nu

source scripts/crossplane.nu
source scripts/kubernetes.nu

delete_crossplane $env.HYPERSCALER

destroy_kubernetes kind