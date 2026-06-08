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

## Validate

```bash
flutter test
```
