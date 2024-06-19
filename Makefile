.PHONY: all $(MAKECMDGOALS)

build:
	docker build -t calculator-app .
	docker build -t calc-web ./web

server:
	docker run --rm --name apiserver --network-alias apiserver --env PYTHONPATH=/opt/calc --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0

test-unit:
	docker run --name unit-tests --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest pytest --cov --cov-report=xml:results/coverage.xml --cov-report=html:results/coverage --junit-xml=results/unit_result.xml -m unit || true
	docker cp unit-tests:/opt/calc/results ./
	docker rm unit-tests || true

test-api:
	docker network create calc-test-api || true
	docker run -d --network calc-test-api --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5001:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run --network calc-test-api --name api-tests --env PYTHONPATH=/opt/calc --env BASE_URL=http://apiserver:5001/ -w /opt/calc calculator-app:latest pytest --junit-xml=results/api_result.xml -m api  || true
	docker cp api-tests:/opt/calc/results ./
	docker stop apiserver || true
	docker rm --force apiserver || true
	docker stop api-tests || true
	docker rm --force api-tests || true
	docker network rm calc-test-api || true

test-e2e:
	docker network create calc-test-e2e || true
	docker stop apiserver || true
	docker rm --force apiserver || true
	docker stop calc-web || true
	docker rm --force calc-web || true
	docker stop e2e-tests || true
	docker rm --force e2e-tests || true
	docker run -d --network calc-test-e2e --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run -d --network calc-test-e2e --name calc-web -p 80:80 calc-web
	docker create --network calc-test-e2e --name e2e-tests cypress/included:4.9.0 --browser chrome || true
	docker cp ./test/e2e/cypress.json e2e-tests:/cypress.json
	docker cp ./test/e2e/cypress e2e-tests:/cypress
	docker start -a e2e-tests || true
	docker cp e2e-tests:/results ./  || true
	docker rm --force apiserver  || true
	docker rm --force calc-web || true
	docker rm --force e2e-tests || true
	docker network rm calc-test-e2e || true

run-web:
	docker run --rm --volume `pwd`/web:/usr/share/nginx/html  --volume `pwd`/web/constants.local.js:/usr/share/nginx/html/constants.js --name calc-web -p 80:80 nginx

stop-web:
	docker stop calc-web


start-sonar-server:
	docker network create calc-sonar || true
	docker run -d --rm --stop-timeout 60 --network calc-sonar --name sonarqube-server -p 9000:9000 --volume `pwd`/sonar/data:/opt/sonarqube/data --volume `pwd`/sonar/logs:/opt/sonarqube/logs sonarqube:8.3.1-community

stop-sonar-server:
	docker stop sonarqube-server
	docker network rm calc-sonar || true

start-sonar-scanner:
	docker run --rm --network calc-sonar -v `pwd`:/usr/src sonarsource/sonar-scanner-cli

pylint:
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest pylint app/ | tee results/pylint_result.txt


deploy-stage:
	docker stop apiserver || true
	docker stop calc-web || true
	docker run -d --rm --name apiserver --network-alias apiserver --env PYTHONPATH=/opt/calc --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run -d --rm --name calc-web -p 80:80 calc-web
