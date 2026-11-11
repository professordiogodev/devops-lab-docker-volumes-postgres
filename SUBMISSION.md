# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `compose.yaml`: PostgreSQL with a named volume and a secret
- [ ] `backup.sh` and `restore.sh`
- [ ] `backups/recovered.sql`: the polls you rescued

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste `docker volume ls` before and after the redeploy. Where was the data after the redeploy, and what is the difference between an anonymous volume and a named one? Why does `docker compose down` not delete it but a new `up` ignores it?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste the commands you used to recover the polls from the orphaned volume without touching it more than necessary. Why mount it read-only first?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. Paste your `compose.yaml`. Where does the password live, how does the container read it (`POSTGRES_PASSWORD_FILE`), and why is a password in `environment:` worse? Where would it be visible (`docker inspect`, `docker compose config`)?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Why is the database port not published to the host in your setup, and how do the other containers reach it? What would publishing it as `5432:5432` change on a laptop in a coffee shop?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. Explain named volume, bind mount and tmpfs in two lines each, and say which one you would use for: the database files, a config file you edit, a scratch directory for secrets.

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./backup.sh` and `./restore.sh`. A backup you have never restored is a hope. How did you prove that yours restores into an empty database?

**Your answer:**

<!-- replace this line with your answer -->

### Q7. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q8. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
