# DataAnnotator

A Docker Compose project for data annotation using Label Studio with ngrok web exposure.

## Overview

This project provides a complete setup for data annotation using:
- **Label Studio**: Web-based data annotation tool
- **ngrok**: Secure tunneling to expose Label Studio to the internet

## Prerequisites

- Docker and Docker Compose installed
- ngrok account and auth token (free at [ngrok.com](https://ngrok.com))

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/PeaceDeveloper/datannotator.git
   cd datannotator
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your credentials:
   - `LABEL_STUDIO_USERNAME`: Admin username for Label Studio
   - `LABEL_STUDIO_PASSWORD`: Admin password for Label Studio  
   - `LABEL_STUDIO_USER_TOKEN`: API token for Label Studio
   - `NGROK_AUTHTOKEN`: Your ngrok auth token from [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)
   - `NGROK_REGION`: ngrok region (us, eu, ap, au, sa, jp, in)

3. **Start the services**
   ```bash
   docker-compose up -d
   ```

4. **Access the applications**
   - **Label Studio**: http://localhost:8080
   - **ngrok Web Interface**: http://localhost:4040
   - **Public URL**: Check ngrok interface for the public tunnel URL

## Usage

### Label Studio
- Access Label Studio at http://localhost:8080
- Login with the credentials you set in the `.env` file
- Create projects and start annotating your data

### ngrok Tunnel
- The ngrok service automatically creates a secure tunnel to Label Studio
- View the public URL in the ngrok web interface at http://localhost:4040
- Share the public URL to allow remote access to your Label Studio instance

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LABEL_STUDIO_USERNAME` | Admin username | `admin` |
| `LABEL_STUDIO_PASSWORD` | Admin password | - |
| `LABEL_STUDIO_USER_TOKEN` | API token | - |
| `NGROK_AUTHTOKEN` | ngrok auth token | - |
| `NGROK_REGION` | ngrok tunnel region | `us` |

### Data Persistence

Label Studio data is persisted using Docker volumes. Your projects and annotations will be preserved between container restarts.

## Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop services and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Troubleshooting

1. **ngrok authentication failed**: Verify your `NGROK_AUTHTOKEN` in the `.env` file
2. **Label Studio not accessible**: Check if port 8080 is available
3. **Services not starting**: Run `docker-compose logs` to see error messages

## Security Notes

- The `.env` file contains sensitive credentials and is excluded from git
- Always use strong passwords for Label Studio admin account
- Be cautious when sharing the ngrok public URL as it exposes your Label Studio instance

## License

Apache License 2.0
