HELM ?= helm
CHART ?= charts/iamra-injector
HELM_UNITTEST_VERSION ?= v0.5.1

.PHONY: helm-unittest-plugin
helm-unittest-plugin:
	@set -e; \
	PLUGINS_DIR="$$( $(HELM) env HELM_PLUGINS )"; \
	UNITTEST_DIR="$$PLUGINS_DIR/helm-unittest"; \
	if [ -f "$$UNITTEST_DIR/plugin.yaml" ] && grep -q "platformHooks" "$$UNITTEST_DIR/plugin.yaml"; then \
		echo "Removing incompatible helm-unittest plugin (platformHooks not supported by this Helm)"; \
		rm -rf "$$UNITTEST_DIR"; \
	fi; \
	if ! $(HELM) plugin list 2>/dev/null | grep -q "^unittest"; then \
		$(HELM) plugin install https://github.com/helm-unittest/helm-unittest --version $(HELM_UNITTEST_VERSION); \
	fi

.PHONY: helm-test
helm-test: helm-unittest-plugin
	$(HELM) unittest $(CHART)
