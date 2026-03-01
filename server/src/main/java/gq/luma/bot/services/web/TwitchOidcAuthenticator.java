package gq.luma.bot.services.web;

import com.nimbusds.oauth2.sdk.ParseException;
import com.nimbusds.oauth2.sdk.http.HTTPResponse;
import com.nimbusds.openid.connect.sdk.OIDCTokenResponseParser;
import com.nimbusds.oauth2.sdk.TokenResponse;
import org.pac4j.core.context.WebContext;
import org.pac4j.oidc.client.OidcClient;
import org.pac4j.oidc.config.OidcConfiguration;
import org.pac4j.oidc.credentials.authenticator.OidcAuthenticator;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.StringJoiner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class TwitchOidcAuthenticator extends OidcAuthenticator {

    private final OidcConfiguration config;
    private final OidcClient client;

    public TwitchOidcAuthenticator(final OidcConfiguration config, final OidcClient client) {
        super(config, client);
        this.config = config;
        this.client = client;
    }

    /**
     * Custom token request which normalizes Twitch's `scope` field when it's returned as a JSON array.
     */
    protected TokenResponse executeTokenRequest(final WebContext context, final String code) throws Exception {
        // Use Twitch token endpoint per docs
        final String tokenEndpoint = "https://id.twitch.tv/oauth2/token";

        final StringBuilder form = new StringBuilder();
        form.append("client_id=").append(URLEncoder.encode(config.getClientId(), StandardCharsets.UTF_8));
        form.append("&client_secret=").append(URLEncoder.encode(config.getSecret(), StandardCharsets.UTF_8));
        form.append("&code=").append(URLEncoder.encode(code, StandardCharsets.UTF_8));
        form.append("&grant_type=authorization_code");
        form.append("&redirect_uri=").append(URLEncoder.encode(client.computeFinalCallbackUrl(context), StandardCharsets.UTF_8));

        final HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(tokenEndpoint))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form.toString()))
                .build();

        final HttpClient http = HttpClient.newBuilder().build();
        final HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());

        // If Twitch returns scope as JSON array, convert it to space-delimited string
        String body = resp.body();
        if (body != null && body.contains("\"scope\":") && body.contains("[")) {
            // Quick and tolerant fix: replace array value with space-joined string
            // This handles e.g. "scope": ["openid","user:read:email"] -> "scope":"openid user:read:email"
            final Pattern p = Pattern.compile("\"scope\"\\s*:\\s*\\[(.*?)\\]", Pattern.DOTALL);
            final Matcher m = p.matcher(body);
            if (m.find()) {
                String inner = m.group(1);
                String[] parts = inner.replaceAll("\"", "").split(",");
                StringJoiner sj = new StringJoiner(" ");
                for (String part : parts) {
                    sj.add(part.trim());
                }
                body = m.replaceFirst("\"scope\":\"" + sj.toString() + "\"");
            }
        }

        final HTTPResponse httpResponse = new HTTPResponse(resp.statusCode());
        httpResponse.setContent(body);

        try {
            return OIDCTokenResponseParser.parse(httpResponse);
        } catch (ParseException e) {
            throw new IOException("Failed to parse token response", e);
        }
    }
}
