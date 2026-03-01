package gq.luma.bot.services.apis;

import com.eclipsesource.json.Json;
import com.eclipsesource.json.JsonObject;
import gq.luma.bot.Luma;
import gq.luma.bot.reference.KeyReference;
import gq.luma.bot.services.Service;
import okhttp3.Request;

import java.io.IOException;
import java.util.Optional;

public class SteamApi implements Service {

    @Override
    public void startService() {
        // No special startup required for the simple OkHttp-based Steam API helper.
    }

    public static class PlayerSummary {
        public final String steamId;
        public final String personaName;

        public PlayerSummary(String steamId, String personaName) {
            this.steamId = steamId;
            this.personaName = personaName;
        }
    }

    public Optional<PlayerSummary> getPlayerSummary(String steamId) throws IOException {
        if (KeyReference.steamKey == null || KeyReference.steamKey.isEmpty()) {
            throw new IllegalStateException("Steam API key is not set in environment variables.");
        }
        final String url = String.format("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=%s&steamids=%s",
                KeyReference.steamKey, steamId);

        Request req = new Request.Builder().url(url).get().build();
        try (okhttp3.Response resp = Luma.okHttpClient.newCall(req).execute()) {
            if (!resp.isSuccessful() || resp.body() == null) return Optional.empty();
            String body = resp.body().string();
            JsonObject root = Json.parse(body).asObject();
            JsonObject response = root.get("response").asObject();
            if (response.get("players") == null || response.get("players").asArray().size() == 0) return Optional.empty();
            JsonObject player = response.get("players").asArray().get(0).asObject();
            String personaname = player.get("personaname").asString();
            String id = player.get("steamid").asString();
            return Optional.of(new PlayerSummary(id, personaname));
        }
    }
}
