import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/components/ui/card';
import AppLayout from '@/layouts/app-layout';
import { webhookTest } from '@/routes';
import { type BreadcrumbItem } from '@/types';
import { Head } from '@inertiajs/react';
import { useState } from 'react';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Webhook Test',
        href: webhookTest().url,
    },
];

interface ProjectComponent {
    name: string;
    description: string;
    price: number;
    quantity: number;
    category: string;
}

interface WebhookPayload {
    project_name: string;
    client_name: string;
    proposal_date: string;
    components: ProjectComponent[];
    total_amount: number;
    currency: string;
    notes: string;
}

// Predefined test data
const SAMPLE_DATA: WebhookPayload = {
    project_name: 'E-Commerce Platform Development',
    client_name: 'Acme Corporation',
    proposal_date: new Date().toISOString(),
    components: [
        {
            name: 'Frontend Development',
            description: 'React-based responsive web application',
            price: 5000,
            quantity: 1,
            category: 'Development',
        },
        {
            name: 'Backend API Development',
            description: 'RESTful API with authentication and authorization',
            price: 4500,
            quantity: 1,
            category: 'Development',
        },
        {
            name: 'Database Design',
            description: 'PostgreSQL database schema and optimization',
            price: 2000,
            quantity: 1,
            category: 'Development',
        },
        {
            name: 'Payment Integration',
            description: 'Stripe payment gateway integration',
            price: 1500,
            quantity: 1,
            category: 'Integration',
        },
        {
            name: 'Admin Dashboard',
            description: 'Full-featured admin panel with analytics',
            price: 3000,
            quantity: 1,
            category: 'Development',
        },
        {
            name: 'Testing & QA',
            description: 'Comprehensive testing and quality assurance',
            price: 2500,
            quantity: 1,
            category: 'Testing',
        },
        {
            name: 'Deployment & DevOps',
            description: 'CI/CD pipeline setup and production deployment',
            price: 1800,
            quantity: 1,
            category: 'DevOps',
        },
        {
            name: 'Documentation',
            description: 'Technical and user documentation',
            price: 1200,
            quantity: 1,
            category: 'Documentation',
        },
    ],
    total_amount: 21500,
    currency: 'USD',
    notes: 'This is a test proposal for n8n webhook integration. All values are sample data.',
};

const N8N_WEBHOOK_URL =
    'https://algowrite.n8n.pipeworker.me/webhook-test/400d85b8-ea9a-459d-b318-4147b90d4316';

export default function WebhookTest() {
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [responseData, setResponseData] = useState<Record<
        string,
        unknown
    > | null>(null);

    const handleSendWebhook = async () => {
        setLoading(true);
        setSuccess(false);
        setError(null);
        setResponseData(null);

        try {
            const response = await fetch(N8N_WEBHOOK_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(SAMPLE_DATA),
            });

            if (!response.ok) {
                const errorText = await response.text();
                let errorMessage = `HTTP ${response.status}: ${response.statusText}`;

                try {
                    const errorJson = JSON.parse(errorText);
                    if (errorJson.message) {
                        errorMessage += ` - ${errorJson.message}`;
                    }
                    if (errorJson.hint) {
                        errorMessage += ` ${errorJson.hint}`;
                    }
                } catch {
                    // If not JSON, append raw text
                    if (errorText) {
                        errorMessage += ` - ${errorText}`;
                    }
                }

                throw new Error(errorMessage);
            }

            const data = await response.json();
            setResponseData(data);
            setSuccess(true);
        } catch (err) {
            setError(
                err instanceof Error ? err.message : 'Failed to send webhook',
            );
        } finally {
            setLoading(false);
        }
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Webhook Test" />
            <div className="flex h-full flex-1 flex-col gap-6 overflow-x-auto rounded-xl p-4">
                <div className="mx-auto w-full max-w-4xl">
                    <Card>
                        <CardHeader>
                            <CardTitle>N8N Webhook Test</CardTitle>
                            <CardDescription>
                                Test your n8n project proposal automation
                                workflow by sending sample data
                            </CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-6">
                                {/* Webhook URL Display */}
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">
                                        Webhook URL
                                    </label>
                                    <div className="flex items-center gap-2 rounded-md border bg-muted p-3">
                                        <code className="flex-1 text-xs break-all">
                                            {N8N_WEBHOOK_URL}
                                        </code>
                                    </div>
                                </div>

                                {/* Sample Data Preview */}
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">
                                        Sample Data Preview
                                    </label>
                                    <div className="max-h-96 overflow-auto rounded-md border bg-muted p-4">
                                        <pre className="text-xs">
                                            {JSON.stringify(
                                                SAMPLE_DATA,
                                                null,
                                                2,
                                            )}
                                        </pre>
                                    </div>
                                </div>

                                {/* Send Button */}
                                <div className="flex items-center justify-between gap-4">
                                    <Button
                                        onClick={handleSendWebhook}
                                        disabled={loading}
                                        size="lg"
                                        className="w-full sm:w-auto"
                                    >
                                        {loading
                                            ? 'Sending...'
                                            : 'Send Test Data'}
                                    </Button>
                                    {success && (
                                        <span className="text-sm text-green-600 dark:text-green-400">
                                            ✓ Webhook sent successfully
                                        </span>
                                    )}
                                </div>

                                {/* Success Alert */}
                                {success && (
                                    <Alert className="border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-950">
                                        <AlertDescription className="text-green-800 dark:text-green-200">
                                            <strong>Success!</strong> Webhook
                                            data sent to n8n workflow.
                                            {responseData && (
                                                <div className="mt-2 rounded border border-green-300 bg-white p-2 dark:border-green-700 dark:bg-green-900">
                                                    <pre className="max-h-48 overflow-auto text-xs">
                                                        {JSON.stringify(
                                                            responseData,
                                                            null,
                                                            2,
                                                        )}
                                                    </pre>
                                                </div>
                                            )}
                                        </AlertDescription>
                                    </Alert>
                                )}

                                {/* Error Alert */}
                                {error && (
                                    <Alert className="border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950">
                                        <AlertDescription className="text-red-800 dark:text-red-200">
                                            <strong>Error:</strong> {error}
                                        </AlertDescription>
                                    </Alert>
                                )}

                                {/* Info Section */}
                                <div className="space-y-3 rounded-md border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-950">
                                    <div>
                                        <h3 className="font-semibold text-blue-900 dark:text-blue-100">
                                            About This Test
                                        </h3>
                                        <p className="text-sm text-blue-800 dark:text-blue-200">
                                            This page sends a predefined project
                                            proposal with{' '}
                                            {SAMPLE_DATA.components.length}{' '}
                                            components totaling $
                                            {SAMPLE_DATA.total_amount.toLocaleString()}{' '}
                                            {SAMPLE_DATA.currency} to your n8n
                                            webhook. The workflow should process
                                            this data and execute your
                                            automation steps.
                                        </p>
                                    </div>
                                    <div className="border-t border-blue-300 pt-3 dark:border-blue-700">
                                        <h4 className="font-semibold text-blue-900 dark:text-blue-100">
                                            ⚠️ Important: Test Webhook Setup
                                        </h4>
                                        <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-blue-800 dark:text-blue-200">
                                            <li>
                                                If using{' '}
                                                <strong>test mode</strong>:
                                                Click "Execute workflow" in n8n
                                                canvas before each test
                                            </li>
                                            <li>
                                                Test webhooks only work for{' '}
                                                <strong>one call</strong> after
                                                activation
                                            </li>
                                            <li>
                                                For unlimited testing:{' '}
                                                <strong>Activate/Deploy</strong>{' '}
                                                your workflow in n8n to use
                                                production webhook
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </AppLayout>
    );
}
