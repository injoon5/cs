#!/bin/bash
# Simulator queue. Whoever is on the first line of queue.txt owns the iPhone 17 simulator.
#   simq.sh join NAME    add NAME to the queue and block until NAME is first
#   simq.sh leave NAME   remove NAME (always do this when done, even after errors)
#   simq.sh show         print the queue
# Lines are "NAME EPOCH". A first line older than 10 minutes is dropped as stale.
DIR=/private/tmp/claude-501
QUEUE=$DIR/sim-queue.txt
LOCK=$DIR/sim-queue.lock
STALE=600

lock() { until mkdir "$LOCK" 2>/dev/null; do perl -e 'select(undef,undef,undef,0.2)'; done; }
unlock() { rmdir "$LOCK" 2>/dev/null; }

touch "$QUEUE"
case "$1" in
join)
    [ -n "$2" ] || { echo "usage: simq.sh join NAME"; exit 2; }
    lock
    grep -q "^$2 " "$QUEUE" || echo "$2 $(date +%s)" >> "$QUEUE"
    unlock
    while true; do
        lock
        read -r head since < <(head -1 "$QUEUE")
        if [ "$head" = "$2" ]; then
            # Refresh the timestamp: the 10 minutes count from getting the simulator.
            sed -i '' "1s/.*/$2 $(date +%s)/" "$QUEUE"
            unlock
            echo "simulator is yours: run 'simq.sh leave $2' when done"
            exit 0
        fi
        # Waiting agents keep their line fresh, so only an owner that went quiet goes stale.
        sed -i '' "s/^$2 .*/$2 $(date +%s)/" "$QUEUE"
        if [ -n "$head" ] && [ $(( $(date +%s) - since )) -gt $STALE ]; then
            sed -i '' '1d' "$QUEUE"
            echo "dropped stale $head"
        fi
        unlock
        perl -e 'select(undef,undef,undef,3)'
    done
    ;;
leave)
    lock
    sed -i '' "/^$2 /d" "$QUEUE"
    unlock
    ;;
show)
    cat "$QUEUE"
    ;;
*)
    echo "usage: simq.sh join|leave NAME, or simq.sh show"; exit 2
    ;;
esac
