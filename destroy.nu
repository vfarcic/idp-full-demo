#!/usr/bin/env nu

source scripts/crossplane.nu
source scripts/kubernetes.nu
source scripts/port.nu

delete_crossplane $env.HYPERSCALER

destroy_kubernetes kind

delete_port