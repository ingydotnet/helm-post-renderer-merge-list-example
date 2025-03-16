default:

test: test-1

test-1:
	VALUES_FILE=values2.yaml \
	helm template cronjob --post-renderer=./ys-merge-env
