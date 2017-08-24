### BASE_IMAGE #################################################################

BASE_IMAGE_TAG		?= edge

### DOCKER_IMAGE ###############################################################

DOCKER_IMAGE_TAGS	?=

### BUILD ######################################################################

# If image configuration variables are not defined, it is assumed that
# the development image is the same as the production image
BUILD_CONFIG		?= $(BASE_IMAGE_TAG)

ifeq ($(strip $(BUILD_CONFIG)),)
DOCKER_BUILD_TARGET	?= docker-tag
DOCKER_REBUILD_TARGET	?= docker-tag
endif

### MK_DOCKER_IMAGE ############################################################

PROJECT_DIR		?= $(abspath ..)
include $(PROJECT_DIR)/Makefile

################################################################################
