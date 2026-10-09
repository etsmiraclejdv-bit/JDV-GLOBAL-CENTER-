'use client';

/**
 * GA4 analytics helpers for JDV CRM.
 * All events are no-ops in non-production or when GA is not configured.
 */

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void;
    dataLayer?: unknown[];
  }
}

function isGAReady(): boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.gtag === 'function' &&
    !!process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID
  );
}

export function trackEvent(
  eventName: string,
  params: Record<string, string | number | boolean | undefined> = {}
): void {
  if (!isGAReady()) return;
  window.gtag!('event', eventName, params);
}

// ─── Key conversion funnel events ────────────────────────────────────────────

/** Fired when a user completes company registration */
export function trackRegistration(params: {
  organizationName?: string;
  sector?: string;
  country?: string;
}): void {
  trackEvent('sign_up', {
    method: 'email',
    organization_name: params.organizationName,
    sector: params.sector,
    country: params.country,
  });
  trackEvent('company_registration', params);
}

/** Fired when a user views or selects a subscription plan */
export function trackPlanSelection(params: {
  planCode: string;
  planName?: string;
  amount?: number;
  currency?: string;
}): void {
  trackEvent('select_content', {
    content_type: 'subscription_plan',
    content_id: params.planCode,
  });
  trackEvent('plan_selected', {
    plan_code: params.planCode,
    plan_name: params.planName,
    value: params.amount,
    currency: params.currency ?? 'XOF',
  });
}

/** Fired when a sale is recorded by a prospecteur or business admin */
export function trackSaleRecorded(params: {
  organizationId?: string;
  amountCents?: number;
  portal: 'business' | 'terrain' | 'super_admin';
}): void {
  trackEvent('sale_recorded', {
    portal: params.portal,
    organization_id: params.organizationId,
    value: params.amountCents ? params.amountCents / 100 : undefined,
    currency: 'XOF',
  });
}

/** Fired when a payment is confirmed (subscription or sale payment) */
export function trackPaymentConfirmed(params: {
  paymentType: 'subscription' | 'sale';
  planCode?: string;
  amountCents?: number;
  organizationId?: string;
}): void {
  trackEvent('purchase', {
    transaction_id: `${params.paymentType}_${Date.now()}`,
    value: params.amountCents ? params.amountCents / 100 : undefined,
    currency: 'XOF',
    payment_type: params.paymentType,
    plan_code: params.planCode,
  });
  trackEvent('payment_confirmed', params);
}

/** Fired when a new prospecteur is created */
export function trackProspecteurCreated(params: {
  organizationId?: string;
  commissionRate?: number;
}): void {
  trackEvent('prospecteur_created', {
    organization_id: params.organizationId,
    commission_rate: params.commissionRate,
  });
}
