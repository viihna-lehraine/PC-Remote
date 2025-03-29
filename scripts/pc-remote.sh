#!/bin/sh

# File: scripts/pc-remote.sh

### === CONFIGURATION === ###
DIR_NAME='/home/viihna/Projects/pc-remote'
DOCKER_COMPOSE_FILE="$DIR_NAME/docker-compose.yml"
SERVICES="db nginx vault"
VERSION="1.0.0"

### === FLAGS === ###
BUILD=false
FULL_REBUILD=false
DESTROY=false
DOCKER_UP=false
DOCKER_UP_DETACHED=false
PUSH_IMAGE=false
SERVICE_RESTART=""
SERVICE_REBUILD=""
SHOW_LOGS=""
TAG_IMAGE=false
SERVICE_TO_TAG=""

### === COLORS === ###
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

set -e

### === AUTO-LOGGING === ###
LOG_DIR="$DIR_NAME/logs/devops"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d_%H-%M-%S').log"

cd "$DIR_NAME"

{
	ASCII_HEADER=$(
		cat <<'EOF'
	        ____   ____   ____                      _
	       |  _ \ / ___| |  _ \ ___ _ __ ___   ___ | |_ ___
	       | |_) | |     | |_) / _ \ '_ ` _ \ / _ \| __/ _ \
	       |  __/| |___  |  _ <  __/ | | | | | (_) | ||  __/
	       |_|    \____| |_| \_\___|_| |_| |_|\___/ \__\___|

	                  DevOps Control Script
	                 Author: Viihna Lehraine

 ..........................:=#%%%%%%%%%%%%%%%%%%%%%###+::..............
.........................-%%%%%%%%#%%%%%%%%%%%%%%%%#***+:.............
.......................:+#%##%%#%%%%%%%%%%%%%%%%%%%%%#*++:............
.....................=%%#%%%%##%%%%%%#%%%%%%%%%%%%%%###**+:...........
....................+#%#%%%%%%#%%%%######%%%%%%%%%%%%##+#*=-..........
..................:+###%%%%%%##############%%%**#*+#%%%%+=+-:.........
..................-*##%%%%%%#++++++**#######%#*#++**=#%%#+==-:........
..................+###%%%%%*++++++++****##%%#***#*+*++#%%#=-:::.......
..................+%%%%%%%#+++++++++****#%%###**#***++####*+=-:.......
..................:*#%####+++++++++++*#%%**###****+*=###+---:::::.....
....................=*####+++++++++*##%#****#####**+*#***=---:-:::--::
......................::::-+++++*#%%@%#*+****#####**=-*****+=-=--+*###
...........................-++*%%%%%%%*++*****#######++##*********####
............................-*%%%%%%%#+++******##########********####*
............................:*%%%%%%%*+++*******#########******+*###*+
.............................:+*#%%#*++++*******##%######********#%#*%
...............................-+***#*+++++++****##**####******##%%%%%
...............................:++##*+++++++++******#####*****#%%%%%%%
.................................::=######*+********####*****#%%%%%%%%
...................................:*##************###%%**+*#%%%%%%%%%
....................................:=--+*********###%%***#%%%%%%%%%%%
..................................:--:..=##*###%%%%%%%##*#%%%%%%%%%%%%
................................::::..:+%####%%%%%%%##**%%%%%%%%%%%%%%
..............................::::....-#%%%%%%%%%%##**#%%%%%%%%%%%%%%%
............................:-:......:+%%%%%%%%%%%#**%%%%%%%%%%%%%%%%%
..........................:-:.......:+%%%%%#%%%%%%##%%%%%%%%%%%%%%%##*
........................:-:........:+%%%%###%%%%%*%%%%%%%%%%%%%%%%#+*%
......................:-:..........:+%%%%##%%%%%%%%%%%%%%%%%%%%#*++**#
....................:-:............:*%%%#*#%%%%%%%%%%%%%%%%%#***+*###%
...........::......:-............::+#%%%#*%%%%%%%%%%%%%%%#***++**#%%%%
........:-+##+:..:+*+--++-....:-+#%%%%%%##%%%%%%%%%@%%%%%%#%%%%##%%%%%
......:-*#%%%%%%%#*#%#####**+*#%%%%%%%%###%%%%%%%%%%#%###%#%%%%%%%%%%%
......-*#%%%%%%#####%%##%%%%%%%%%%%%%%%#%%%%%%%%#####%%#%%#%##%%%%%%%%
......:-*####****###%%#%%%%%%%%%%%%%%%#%%%%%#*###*#######%%%@%%%%%%%%%
..........:=++++*#%#**#%###%%%%%%%%%%%%%%%***##*****#####%%%%%%%%%%%%%
...........:=+++*+***#####%%%%%%%%%%%###***####%%%%%%%%%%%%%%%%%%%%%%%

EOF
	)

	print_ascii_art() {
		printf "%s\n" "$ASCII_HEADER"
	}

	print_help() {
		echo "${CYAN}**PC Remote - DevOps Control Script**${NC}"
		echo "${YELLOW}Usage:${NC} ./pc-remote.sh [flags] — or launch with no flags to enter interactive mode"
		echo ""
		echo "General Options (CLI or Interactive)"
		echo "  -h, help             Show this help menu"
		echo "  version              Show current script version"
		echo ""
		echo "Service Management"
		echo "  -d, down             Destroy all containers"
		echo "  -u, up               Start all services in foreground"
		echo "  -U, up-detached      Start all services in detached mode"
		echo "  -r, restart <name>   Restart a specific service"
		echo "  -R, rebuild <name>   Rebuild a specific service"
		echo "  -l, logs <name>      Show logs for a specific service"
		echo ""
		echo "Build & Deployment"
		echo "  -b, build            Build all services"
		echo "  -B, full-rebuild     Stop, rebuild, and restart everything"
		echo "  -p, push             Push Docker images to Docker Hub"
		echo "  -t, tag <name>       Tag a specific service for pushing"
		echo ""
		echo "Vault Management"
		echo "  vault_reinit         Reset, unseal, and start Vault"
		echo "  vault_up             Unseal and start Vault (no reset)"
		echo "Extra"
		echo "  status               Show running container status"
		echo "  exit                 Leave interactive mode"
		echo ""
	}

	### === SERVICE MANAGEMENT FUNCTIONS === ###
	destroy_services() {
		echo "Destroying all containers..."
		docker compose -f "$DOCKER_COMPOSE_FILE" -f "$DIR_NAME/docker-compose.override.yml" down -v
		echo "${GREEN}All containers removed.${NC}"
	}

	start_services() {
		if [ "$DOCKER_UP_DETACHED" = true ]; then
			echo "${CYAN}Starting services in detached mode...${NC}"
			docker compose -f "$DOCKER_COMPOSE_FILE" -f "$DIR_NAME/docker-compose.override.yml" up -d
		else
			echo "${CYAN}Starting services in foreground...${NC}"
			docker compose -f "$DOCKER_COMPOSE_FILE" -f "$DIR_NAME/docker-compose.override.yml" up
		fi
	}

	restart_service() {
		SERVICE=$1
		if [ -z "$SERVICE" ]; then
			echo "${YELLOW}Please specify a service to restart.${NC}"
		else
			echo "${CYAN}Restarting service: $SERVICE${NC}"
			docker restart "$SERVICE"
		fi
	}

	rebuild_service() {
		SERVICE=$1
		if [ -z "$SERVICE" ]; then
			echo "${YELLOW}Please specify a service to rebuild.${NC}"
		else
			echo "${CYAN}Rebuilding service: $SERVICE${NC}"
			docker compose -f "$DOCKER_COMPOSE_FILE" up --force-recreate --build -d "$SERVICE"
		fi
	}

	show_logs() {
		SERVICE=$1
		if [ -z "$SERVICE" ]; then
			echo "${YELLOW}Please specify a service to show logs.${NC}"
		else
			echo "${CYAN}Showing logs for: $SERVICE${NC}"
			docker logs -f "$SERVICE"
		fi
	}

	build_services() {
		echo "Building all services..."
		docker compose -f "$DOCKER_COMPOSE_FILE" build
		echo "${GREEN}Build complete.${NC}"
	}

	full_rebuild() {
		echo "Performing full rebuild..."
		docker compose -f "$DOCKER_COMPOSE_FILE" down
		build_services
		start_services
		echo "${GREEN}Full rebuild complete.${NC}"
	}

	push_images() {
		echo "Pushing latest images to Docker Hub..."
		for SERVICE in $SERVICES; do
			echo "Pushing image for: $SERVICE"
			docker push "viihnatech/pc-remote-$SERVICE:latest"
		done
		echo "${GREEN}Image push complete.${NC}"
	}

	tag_image() {
		SERVICE=$1
		if [ -z "$SERVICE" ]; then
			echo "${YELLOW}Please specify a service to tag.${NC}"
		else
			echo "Tagging image for: $SERVICE"
			docker tag "viihnatech/pc-remote-$SERVICE:latest" "viihnatech/pc-remote-$SERVICE:$(date +%Y%m%d%H%M)"
			echo "${GREEN}Image tagged.${NC}"
		fi
	}

	vault_reinit() {
		echo "${YELLOW}This will destroy and reset Vault. Are you sure? (yes/no)${NC}"
		read -r CONFIRM
		if [ "$CONFIRM" = "yes" ]; then
			echo "${CYAN}Resetting, unsealing, and starting Vault...${NC}"
			cd "$DIR_NAME/scripts/vault"
			./reset-vault.sh && sudo ./unseal.sh && ./up.sh
			cd "$DIR_NAME"
		else
			echo "${RED}Vault reset canceled.${NC}"
		fi
	}

	vault_up() {
		echo "${CYAN}Unsealing and starting Vault (no reset)...${NC}"
		cd "$DIR_NAME/scripts/vault"
		sudo ./unseal.sh && ./up.sh
		cd "$DIR_NAME"
	}

	# POSIX-safe flag expansion for single-dash chains like -bdUl
	expanded_args=""
	for arg in "$@"; do
		case "$arg" in
		--*) # long options — leave untouched
			expanded_args="$expanded_args $arg"
			;;
		-?*) # chained short options like -bdUl
			# extract each character after the first dash
			flagstr=$(echo "$arg" | cut -c2-)
			while [ -n "$flagstr" ]; do
				expanded_args="$expanded_args -$(printf "%s" "$flagstr" | cut -c1)"
				flagstr=$(printf "%s" "$flagstr" | cut -c2-)
			done
			;;
		*) # Positional args
			expanded_args="$expanded_args $arg"
			;;
		esac
	done

	# reset positional args
	# shellcheck disable=SC2086
	set -- $expanded_args

	### === ARGUMENT PARSING === ###
	while getopts ":bBdUur:R:l:pt:hVv" opt; do
		case "$opt" in
		b) BUILD=true ;;
		B) FULL_REBUILD=true ;;
		d) DESTROY=true ;;
		u) DOCKER_UP=true ;;
		U) DOCKER_UP_DETACHED=true ;;
		r) SERVICE_RESTART="$OPTARG" ;;
		R) SERVICE_REBUILD="$OPTARG" ;;
		l) SHOW_LOGS="$OPTARG" ;;
		p) PUSH_IMAGE=true ;;
		t)
			TAG_IMAGE=true
			SERVICE_TO_TAG="$OPTARG"
			;;
		v)
			vault_up
			exit 0
			;;
		V)
			vault_reinit
			exit 0
			;;
		h)
			print_help
			exit 0
			;;
		*)
			echo "${RED}Invalid option: -$OPTARG${NC}"
			exit 1
			;;
		esac
	done

	if [ "$1" = "vault-reinit" ]; then
		vault_reinit
		exit 0
	fi

	if [ "$1" = "vault-up" ]; then
		vault_up
		exit 0
	fi

	### === EXECUTE ACTIONS BASED ON FLAGS === ###
	if [ "$BUILD" = true ]; then build_services; fi
	if [ "$FULL_REBUILD" = true ]; then full_rebuild; fi
	if [ "$DESTROY" = true ]; then destroy_services; fi
	if [ "$DOCKER_UP" = true ] || [ "$DOCKER_UP_DETACHED" = true ]; then start_services; fi
	if [ -n "$SERVICE_RESTART" ]; then restart_service "$SERVICE_RESTART"; fi
	if [ -n "$SERVICE_REBUILD" ]; then rebuild_service "$SERVICE_REBUILD"; fi
	if [ -n "$SHOW_LOGS" ]; then show_logs "$SHOW_LOGS"; fi
	if [ "$PUSH_IMAGE" = true ]; then push_images; fi
	if [ "$TAG_IMAGE" = true ]; then tag_image "$SERVICE_TO_TAG"; fi

	### === INTERACTIVE MODE === ###
	if [ -z "$STARTED" ]; then
		clear
		print_ascii_art
		STARTED=true
	fi

	echo "----------------------------------------------------------------------"
	echo "Enter a command, or type **help** for a list of commands."

	while true; do
		printf "\n🔹 PC Remote > "
		read -r CMD ARGS
		CMD=$(echo "$CMD" | tr '[:upper:]' '[:lower:]')
		case "$CMD" in
		version)
			echo "${GREEN}PC Remote DevOps Script v$VERSION${NC}"
			echo "Author: Viihna Lehraine — $(date +%Y)"
			;;
		help)
			print_help
			;;
		-h)
			print_help
			;;
		down)
			destroy_services
			;;
		-d)
			destroy_services
			;;
		restart)
			restart_service "$ARGS"
			;;
		rebuild)
			rebuild_service "$ARGS"
			;;
		logs)
			show_logs "$ARGS"
			;;
		build)
			build_services
			;;
		-b)
			build_services
			;;
		full-rebuild)
			full_rebuild
			;;
		-B)
			full_rebuild
			;;
		push)
			push_images
			;;
		-p)
			push_images
			;;
		tag)
			tag_image "$ARGS"
			;;
		up)
			DOCKER_UP=true
			start_services
			;;
		-u)
			DOCKER_UP=true
			start_services
			;;
		up-detached)
			DOCKER_UP=true
			DOCKER_UP_DETACHED=true
			start_services
			;;
		-U)
			DOCKER_UP=true
			DOCKER_UP_DETACHED=true
			start_services
			;;
		-v)
			vault_up
			;;
		-V)
			vault_reinit
			;;

		status)
			echo "${CYAN}Docker container status:${NC}"
			docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
			;;
		vault_reinit)
			vault_reinit
			;;
		vault_up)
			vault_up
			;;
		exit)
			echo "Exiting interactive mode."
			exit 0
			;;
		*)
			echo "${RED}Unknown command: '$CMD'. Type 'help' for available commands.${NC}"
			;;
		esac
	done
} 2>&1 | tee -a "$LOG_FILE"
