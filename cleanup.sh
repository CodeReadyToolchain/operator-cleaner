#! /bin/bash

# pathes to all relevant (stage and prod) member cluster kube config files
clusters=( ${PATH_TO_KUBECONFIG}/m1-config ${PATH_TO_KUBECONFIG}/m2-config ${PATH_TO_KUBECONFIG}/m3-config ${PATH_TO_KUBECONFIG}/m4-config )

# Operator namespace
namespaceName=rhoas-operator

# Operator CRDs
kinds=( cloudserviceaccountrequests.rhoas.redhat.com cloudservicesrequests.rhoas.redhat.com kafkaconnections.rhoas.redhat.com serviceregistryconnections.rhoas.redhat.com )

# Clean up
for kconfig in "${clusters[@]}"
do
    echo "--------------------------------------"
    echo ""
    echo "Cleaning up $kconfig cluster..."
    echo ""
    echo ""

    # Delete all CRs

    for i in "${kinds[@]}"
    do
        echo "Deleting $i from all namespaces..."
        oc delete --all --all-namespaces $i --wait --kubeconfig=$kconfig
    done

    # Delete all subscriptions, install plans, csvs from the operator namespace

    echo "Deleting subscriptions from ${namespaceName} namespace..."
    oc delete sub --all -n ${namespaceName} --ignore-not-found --wait --kubeconfig=$kconfig
    echo "Deleting instal plans from ${namespaceName} namespace..."
    oc delete installplan --all -n ${namespaceName} --ignore-not-found --wait --kubeconfig=$kconfig
    echo "Deleting CSVs from ${namespaceName} namespace..."
    oc delete csvs --all -n ${namespaceName} --ignore-not-found --wait --kubeconfig=$kconfig

    # oc delete catalogsource <NAME> -n openshift-marketplace --kubeconfig=$kconfig

    # Delete the operator namespace/project

    echo "Deleting ${namespaceName} namespace..."
    oc delete project ${namespaceName} --ignore-not-found --wait --kubeconfig=$kconfig

    # echo "Deleting the finalizers from the ${namespaceName} namespace..."
    # oc get namespace ${namespaceName} --kubeconfig=$kconfig -o json \
    #   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
    #   | oc replace --raw /api/v1/namespaces/${namespaceName}/finalize --kubeconfig=$kconfig -f -

    # Restart OLM

    echo "Restarting OLM..."
    oc delete pod --all -n openshift-operator-lifecycle-manager --ignore-not-found --wait --kubeconfig=$kconfig
    oc delete pod --all -n openshift-marketplace --ignore-not-found --wait --kubeconfig=$kconfig

    # Delete CRDs

    for i in "${kinds[@]}"
    do
        echo "Deleting CRD $i..."
        oc delete crd $i --kubeconfig=$kconfig
    done

    # Delete webhook configurations

    echo "Deleting webhook configurations..."
    oc delete ValidatingWebhookConfiguration -l olm.owner.namespace=${namespaceName} --kubeconfig=$kconfig
    oc delete MutatingWebhookConfiguration -l olm.owner.namespace=${namespaceName} --kubeconfig=$kconfig

done