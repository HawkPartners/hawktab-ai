import { AppBreadcrumbs } from '@/components/app-breadcrumbs';

export default function SettingsPage() {
  return (
    <div>
      <AppBreadcrumbs segments={[{ label: 'Settings' }]} />

      <div className="mt-6">
        <h1 className="text-2xl font-bold tracking-tight mb-2">Settings</h1>
        <p className="text-muted-foreground">
          Settings and configuration options coming soon.
        </p>
      </div>
    </div>
  );
}
