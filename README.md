![Discord Shield](https://discordapp.com/api/guilds/146404426746167296/widget.png?style=shield)

# LumaBot

Discord Bot and web dashboard for verifying server members and other cool
features like stream announcements, moderation tools, and more!

# Usage

You'll need a Discord bot token, a MySQL database, and API keys from Steam and Twitch.

1. Set up a MySQL `luma` database with a privileged user. You can do this on
   a local Docker MySQL instance or any MySQL server.

   ```sql
   CREATE DATABASE IF NOT EXISTS luma; GRANT ALL PRIVILEGES ON luma.* TO '<username>'@'%' IDENTIFIED BY '<password>';
   ```

2. Create an `.env` file with the following contents:

   ```env
   DISCORD_BOT_TOKEN=<>
   DISCORD_CLIENT_ID=<>
   DISCORD_CLIENT_SECRET=<>
   MYSQL_HOST=localhost
   MYSQL_USER=<username>
   MYSQL_PASS=<password>
   STEAM_KEY=<>
   TWITCH_CLIENT_ID=<>
   TWITCH_CLIENT_SECRET=<>
   ```

3. Build and run the Docker image with

   ```sh
   docker build -t lumabot .
   docker run --env-file .env -p 80:80 --restart unless-stopped -d lumabot
   ```

# #bot-spam `?l ping`

What time can you get?

[![Discord Invite](https://invidget.switchblade.xyz/hRwE4Zr)](https://discord.com/invite/hRwE4Zr)
