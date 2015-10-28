default: build

build:
	docker build -t mksm/amz_bestsellers .

push:
	docker push mksm/amz_bestsellers

package:
	zip -r tmp/release.zip .ebextensions/ .elasticbeanstalk/ Dockerrun.aws.json

deploy:
	eb deploy
