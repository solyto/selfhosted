# Brief: Fix setup.sh for all OSes

type: feature
id: plus
branch: feature/plus_fix-setup-sh-for-all-oses
date: 2026-10-14
author: Leander Muskalla

## What

A user trying to selfhost solyto on Arch has reported that the setup.sh script dies on trying to change ownership of storage/ to www-data. That makes sense since Arch has no www-data user. We were able to fix the issue by changing that one line in the setup.sh script from chown -R www-data:www-data to chown -R 33:33.
However, I think we might need a better solution overall that works with all OSes.

## Why

<!-- Why does this need to exist? What problem does it solve for the user? -->

## Out of scope

<!-- What are we explicitly NOT doing in this job? -->

## Notes

<!-- Anything the analyst or developer should know before starting. -->
