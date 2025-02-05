#!/bin/bash
# ogpreview.sh - Generate an Open Graph & Social Media preview page

# Check if a URL argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <url>"
    exit 1
fi

URL="$1"

# Fetch the webpage HTML once
html=$(curl -s "$URL")
if [ -z "$html" ]; then
    echo "Error: Unable to fetch URL: $URL"
    exit 1
fi

# Function to extract a meta tag’s content using Perl
extract_meta() {
    local key="$1"
    # This Perl one-liner looks for a meta tag where property or name equals the given key
    perl -nle 'print $1 if /<meta\s+[^>]*(?:property|name)\s*=\s*"\Q'"$key"'\E"[^>]*content\s*=\s*"([^"]+)"/i' <<< "$html" | head -n1
}

# Extract key preview meta tags
OG_TITLE=$(extract_meta "og:title")
OG_DESCRIPTION=$(extract_meta "og:description")
OG_IMAGE=$(extract_meta "og:image")
OG_URL=$(extract_meta "og:url")

TWITTER_TITLE=$(extract_meta "twitter:title")
TWITTER_DESCRIPTION=$(extract_meta "twitter:description")
TWITTER_IMAGE=$(extract_meta "twitter:image")

# Set default values if not found
OG_TITLE=${OG_TITLE:-"No Title Found"}
OG_DESCRIPTION=${OG_DESCRIPTION:-"No Description Found"}
OG_IMAGE=${OG_IMAGE:-"https://via.placeholder.com/600x315.png?text=No+Image"}
OG_URL=${OG_URL:-$URL}

TWITTER_TITLE=${TWITTER_TITLE:-$OG_TITLE}
TWITTER_DESCRIPTION=${TWITTER_DESCRIPTION:-$OG_DESCRIPTION}
TWITTER_IMAGE=${TWITTER_IMAGE:-$OG_IMAGE}

# Gather all meta tags that have property or name starting with "og:" or "twitter:" using Perl
all_meta=$(perl -nle '
  while (/<meta\s+[^>]*(?:property|name)\s*=\s*"((?:og|twitter):[^"]+)"[^>]*content\s*=\s*"([^"]+)"/ig) {
      print "$1\t$2";
  }
' <<< "$html")

# Build table rows from the extracted meta tags (each line is tab-separated)
meta_rows=""
while IFS=$'\t' read -r tag content; do
    # Escape some HTML special characters for safe output
    safe_tag=$(echo "$tag" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    safe_content=$(echo "$content" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    meta_rows="${meta_rows}<tr><td>${safe_tag}</td><td>${safe_content}</td></tr>\n"
done <<< "$all_meta"

# Save output to a temporary HTML file
TEMP_HTML="/tmp/ogpreview.html"

cat <<EOF > "$TEMP_HTML"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Open Graph Preview</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background-color: #f9f9f9; }
    h1, h2, h3 { color: #333; }
    .container { max-width: 800px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0px 0px 10px rgba(0,0,0,0.1); }
    .section { margin-bottom: 20px; }
    .preview { border: 1px solid #ddd; padding: 10px; border-radius: 6px; background: #fff; }
    .image { width: 100%; max-height: 400px; object-fit: cover; border-radius: 6px; }
    .meta { font-size: 14px; color: #555; }
    .social-preview { display: flex; gap: 10px; justify-content: center; margin-top: 20px; }
    .social-card { width: 250px; text-align: center; padding: 10px; border-radius: 8px; background: #fff; box-shadow: 0px 0px 5px rgba(0,0,0,0.1); }
    .social-card img { width: 100%; height: 150px; object-fit: cover; border-radius: 6px; }
    .social-card h3 { font-size: 16px; margin: 10px 0 5px; }
    .social-card p { font-size: 12px; color: #666; }
    .facebook { border-top: 3px solid #1877F2; }
    .twitter { border-top: 3px solid #1DA1F2; }
    .tiktok { border-top: 3px solid #000; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    table, th, td { border: 1px solid #ccc; }
    th, td { padding: 8px; text-align: left; }
  </style>
</head>
<body>
  <h1>Open Graph & Social Media Preview</h1>
  <div class="container">
    <!-- Website Preview Section -->
    <div class="section preview">
      <h2>Website Preview</h2>
      <img class="image" src="$OG_IMAGE" alt="OG Image">
      <h3>$OG_TITLE</h3>
      <p class="meta">$OG_DESCRIPTION</p>
      <p><a href="$OG_URL" target="_blank">$OG_URL</a></p>
    </div>

    <!-- Social Media Previews Section -->
    <h2>Social Media Previews</h2>
    <div class="social-preview">
      <!-- Facebook Preview -->
      <div class="social-card facebook">
        <img src="$OG_IMAGE" alt="Facebook Preview">
        <h3>$OG_TITLE</h3>
        <p>$OG_DESCRIPTION</p>
      </div>

      <!-- Twitter Preview -->
      <div class="social-card twitter">
        <img src="$TWITTER_IMAGE" alt="Twitter Preview">
        <h3>$TWITTER_TITLE</h3>
        <p>$TWITTER_DESCRIPTION</p>
      </div>

      <!-- TikTok Preview -->
      <div class="social-card tiktok">
        <img src="$OG_IMAGE" alt="TikTok Preview">
        <h3>$OG_TITLE</h3>
        <p>$OG_DESCRIPTION</p>
      </div>
    </div>

    <!-- All Meta Tags Section -->
    <div class="section meta-tags">
      <h2>All OG/Twitter Meta Tags</h2>
      <table>
        <tr>
          <th>Tag</th>
          <th>Content</th>
        </tr>
        $(echo -e "$meta_rows")
      </table>
    </div>
  </div>
</body>
</html>
EOF

# Open the generated preview in the default browser (works on Linux/macOS)
xdg-open "$TEMP_HTML" 2>/dev/null || open "$TEMP_HTML" 2>/dev/null
