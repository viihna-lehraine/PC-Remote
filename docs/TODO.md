To Do
---

1. Clean up docker startup process and get a clean start
2. Ensure default root token is backed up and never shredded
3. Create Vault user with least privilege possible and seal off Root usage
4. Do the same on the DB container
5. Ensure Nginx is not running as root
6. Check that all filesystems have root password disabled
7. Orchestrate TLS cert rotation via Vault
8. Create role for Backend that allows it to connect to Database and read other necessary secrets
9. Configure Tailscale as WAN endpoint
10. Ensure that only intentionally exposed endpoints are accessible for each container
11. Write interactive script for testing endpoints
12. Implement secure way of requesting client cert from Vault

---

## Extra Credit

1. Modularize and abstract pc-remote.sh for use in other projects
2. Do the same for remaining scripts
3. Explore Python conversions where appropriate