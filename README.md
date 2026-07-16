# prm_frontend

Flutter frontend for PRM project.

## Initial Project Structure

```text
lib/
	app/
		app.dart
	routes/
		app_routes.dart
		app_router.dart
	core/
		network/
			api_client.dart
			api_endpoints.dart
	api/
		services/
			user_api_service.dart
	features/
		chat/
			data/
			domain/
			presentation/
		home/
			presentation/
				home_page.dart
	main.dart
```

## Packages

- `go_router`: route management
- `dio`: HTTP client

## Init Checklist (Frontend)

1. Create Flutter project with org and project name.
2. Add base architecture: `app`, `routes`, `core`, `api`, `features`.
3. Configure router and default route.
4. Configure API base client and endpoint constants.
5. Add first feature screen and wire to router.
6. Add/adjust widget test for app bootstrap.
7. Run dependency install and tests before push.

## Run Locally

```bash
flutter pub get
flutter run
```

The default API URL is `http://10.0.2.2:3000`, which reaches localhost from an
Android emulator. Override it for a physical device or deployed backend:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

The chatbot calls `POST /api/chat`. The backend must have `KIMI_API_KEY`
configured before it can return AI responses.

## Validate

```bash
flutter test
```
