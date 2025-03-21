#!/bin/sh

### === CONFIGURATION === ###
DIR_NAME='/home/viihna/Projects/pc-remote'
DOCKER_COMPOSE_FILE="$DIR_NAME/docker-compose.yml"
SERVICES="nginx"

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

set -e

cd "$DIR_NAME"

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
	echo "📖 **PC Remote - DevOps Control Script**"
	echo "Usage: **pc-remote.sh** [options] OR just run **pc-remote.sh** for interactive mode."
	echo ""
	echo "🔹 **General Options**"
	echo "  -h           Show this help menu"
	echo ""
	echo "🔹 **Service Management**"
	echo "  -d           Destroy all containers"
	echo "  -u           Start all services in foreground"
	echo "  -U           Start all services in detached mode"
	echo "  -r <name>    Restart a specific service"
	echo "  -R <name>    Rebuild a specific service"
	echo "  -l <name>    Show logs for a specific service"
	echo ""
	echo "🔹 **Build & Deployment**"
	echo "  -b           Build all services"
	echo "  -B           Full rebuild (stops, rebuilds, and restarts everything fresh)"
	echo "  -p           Push all images to Docker Hub"
	echo "  -t <name>    Tag a specific service before pushing"
	echo ""
}

### === SERVICE MANAGEMENT FUNCTIONS === ###
destroy_services() {
	echo "Destroying all containers..."
	docker compose -f "$DOCKER_COMPOSE_FILE" down -v
	echo "All containers removed."
}

start_services() {
	if [ "$DOCKER_UP_DETACHED" = true ]; then
		echo "Starting services in detached mode..."
		docker compose -f "$DOCKER_COMPOSE_FILE" up -d
	else
		echo "Starting services in foreground..."
		docker compose -f "$DOCKER_COMPOSE_FILE" up
	fi
}

restart_service() {
	SERVICE=$1
	if [ -z "$SERVICE" ]; then
		echo "Please specify a service to restart."
	else
		echo "Restarting service: $SERVICE"
		docker restart "$SERVICE"
	fi
}

rebuild_service() {
	SERVICE=$1
	if [ -z "$SERVICE" ]; then
		echo "Please specify a service to rebuild."
	else
		echo "Rebuilding service: $SERVICE"
		docker compose -f "$DOCKER_COMPOSE_FILE" up --force-recreate --build -d "$SERVICE"
	fi
}

show_logs() {
	SERVICE=$1
	if [ -z "$SERVICE" ]; then
		echo "Please specify a service to show logs."
	else
		echo "Showing logs for: $SERVICE"
		docker logs -f "$SERVICE"
	fi
}

build_services() {
	echo "Building all services..."
	docker compose -f "$DOCKER_COMPOSE_FILE" build
	echo "Build complete."
}

full_rebuild() {
	echo "Performing full rebuild..."
	docker compose -f "$DOCKER_COMPOSE_FILE" down
	build_services
	start_services
	echo "Full rebuild complete."
}

push_images() {
	echo "Pushing latest images to Docker Hub..."
	for SERVICE in $SERVICES; do
		echo "Pushing image for: $SERVICE"
		docker push "viihnatech/pc-remote-$SERVICE:latest"
	done
	echo "Image push complete."
}

tag_image() {
	SERVICE=$1
	if [ -z "$SERVICE" ]; then
		echo "Please specify a service to tag."
	else
		echo "Tagging image for: $SERVICE"
		docker tag "viihnatech/pc-remote-$SERVICE:latest" "viihnatech/pc-remote-$SERVICE:$(date +%Y%m%d%H%M)"
		echo "Image tagged."
	fi
}

### === ARGUMENT PARSING === ###
while getopts ":bBdUur:R:l:pt:h" opt; do
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
	h)
		print_help
		exit 0
		;;
	*)
		echo "❌ Invalid option: -$OPTARG"
		exit 1
		;;
	esac
done

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
	print_ascii_art
	STARTED=true
fi

echo "----------------------------------------------------------------------"
echo "Enter a command, or type **help** for a list of commands."

while true; do
	printf "\n🔹 PC Remote > "
	read -r CMD ARGS
	case "$CMD" in
	help)
		print_help
		;;
	down)
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
	full-rebuild)
		full_rebuild
		;;
	push)
		push_images
		;;
	tag)
		tag_image "$ARGS"
		;;
	status)
		echo "🌐 Docker container status:"
		docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
		;;
	exit)
		echo "👋 Exiting interactive mode."
		exit 0
		;;
	*)
		echo "❌ Unknown command: '$CMD'. Type 'help' for available commands."
		;;
	esac
done
