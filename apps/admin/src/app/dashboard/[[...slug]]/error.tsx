"use client";
export default function ErrorPage({ reset }: { reset: () => void }) {
  return <div className="dashboard-page"><section className="empty-state error-state"><h1>We couldn’t load this page</h1><p>Try the request again. No changes were made.</p><button className="primary-action" onClick={reset}>Try again</button></section></div>;
}
