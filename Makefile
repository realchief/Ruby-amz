default: build

build:
	docker build -t mksm/amz_products .

push:
	docker push mksm/amz_products

package:
	zip -r tmp/release.zip .ebextensions/ .elasticbeanstalk/ Dockerrun.aws.json

deploy:
	eb deploy
