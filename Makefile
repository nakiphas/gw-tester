# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

build:
	for image in enb pgw sgw mme ; do \
		sudo docker buildx build --platform linux/amd64,linux/arm64 -t electrocucaracha/$$image:0.7.5 --push --file $$image/Dockerfile $$image ; \
	done
	sudo docker image prune --force
pull:
	sudo docker-compose --file docker/main.yml --file docker/overlay.yml --file docker/demo.yml pull

docker-deploy: docker-undeploy
	sudo docker-compose --file docker/main.yml --file docker/overlay.yml up --force-recreate --detach --no-build
docker-undeploy:
	sudo docker-compose --file docker/main.yml --file docker/overlay.yml down --remove-orphans
docker-deploy-demo: docker-undeploy-demo
	sudo docker-compose --file docker/main.yml --file docker/overlay.yml --file docker/demo.yml up --force-recreate --detach --no-build
docker-undeploy-demo:
	sudo docker-compose --file docker/main.yml --file docker/overlay.yml --file docker/demo.yml down --remove-orphans
docker-logs:
	for service in pgw sgw mme enb; do \
		echo "--- $${service} ---"; \
		docker logs docker_$${service}_1; \
	done
docker-debug:
	sudo docker-compose --file docker/main.yml --file docker/overlay.yml --file docker/demo.yml logs --follow external_client

k8s-deploy:
	cd ./k8s/"$${MULTI_CNI:-multus}"; ./deploy_main.sh
k8s-undeploy:
	cd ./k8s/"$${MULTI_CNI:-multus}"; ./undeploy_main.sh
k8s-deploy-demo:
	cd ./k8s/"$${MULTI_CNI:-multus}"; ./deploy_demo.sh
k8s-undeploy-demo:
	cd ./k8s/"$${MULTI_CNI:-multus}"; ./undeploy_demo.sh
k8s-logs:
	for pod in pgw sgw mme enb; do \
		echo "--- $${pod} ---"; \
		kubectl logs $${pod} ; \
	done
k8s-debug:
	kubectl logs -f external-client
k8s-configure:
	for pod in pgw sgw mme enb; do \
		echo "--- $${pod} ---"; \
		kubectl logs $${pod} -c configure ; \
	done

helm-deploy:
	cd ./k8s/"$${MULTI_CNI:-multus}"; PKG_MGR=helm ./deploy_main.sh
helm-undeploy:
	cd ./k8s/"$${MULTI_CNI:-multus}"; PKG_MGR=helm ./undeploy_main.sh
helm-deploy-demo: k8s-deploy-demo
helm-undeploy-demo: k8s-undeploy-demo
helm-logs:
	for deployment in pgw sgw mme enb; do \
		echo "--- $${deployment} ---"; \
		kubectl logs -l=app.kubernetes.io/name=$${deployment} ; \
	done
helm-debug: k8s-debug
helm-configure:
	for deployment in pgw sgw mme enb; do \
		echo "--- $${deployment} ---"; \
		kubectl logs -l=app.kubernetes.io/name=$${deployment} -c configure; \
	done
