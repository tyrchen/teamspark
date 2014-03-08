CHECK=\033[32m✔\033[39m
DONE="\n$(CHECK) Done.\n"

SERVER=docker
SERVER_USER=tchen
PROJECT=teamspark
DEPLOY_PATH=deployment/$(PROJECT)
BUILD=build
APP=$(BUILD)/app
DB=$(BUILD)/db


DOCKER=$(shell which docker)
METEOR=$(shell which meteor)
SSH=$(shell which ssh)
TAR=$(shell which tar)
RSYNC=$(shell which rsync)
MKDIR=$(shell which mkdir)
CP=$(shell which cp)

remote_deploy:
	@$(RSYNC) -au --exclude .meteor --exclude build . $(SERVER):/home/$(SERVER_USER)/deployment/$(PROJECT)
	@$(SSH) -t $(SERVER) "echo Deploy $(PROJECT) to the $(SERVER) server.; cd $(DEPLOY_PATH); make deploy;"

prepare:
	@$(MKDIR) -p $(APP) $(DB)
	@$(METEOR) bundle tmp.tgz
	@$(TAR) zxvf tmp.tgz
	@$(RSYNC) -au bundle $(APP)
	@$(CP) docker/app.docker $(APP)
	@$(CP) docker/db.* $(DB)

app_image:
	@cd $(APP); $(DOCKER) build -t tchen/ts_app .

db_image:
	@cd $(DB); $(DOCKER) build -t tchen/ts_mongo .


deploy: prepare app_image
	@$(ECHO) $(DONE)