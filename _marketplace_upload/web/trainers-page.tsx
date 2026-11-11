'use client';

import { useEffect, useState } from 'react';

type Trainer = {
  id: string;
  display_name: string;
  headline?: string;
  avatar_url?: string;
  rating_average?: number;
  starting_price?: string;
  currency?: string;
  specialties?: { name: string }[];
};

export default function TrainersPage() {
  const [trainers, setTrainers] = useState<Trainer[]>([]);
  const [query, setQuery] = useState('');
  const [error, setError] = useState('');

  async function load(q = query) {
    setError('');
    const response = await fetch(`/api/trainers?q=${encodeURIComponent(q)}&per_page=24`);
    const body = await response.json();
    if (!response.ok || body.success === false) {
      setError(body.message || 'تعذر تحميل المدربين');
      return;
    }
    setTrainers(body.data?.trainers || []);
  }

  useEffect(() => {
    load('');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <main style={{ maxWidth: 1080, margin: '0 auto', padding: '32px 16px', direction: 'rtl' }}>
      <h1 style={{ fontSize: 32, marginBottom: 8 }}>احجز جلسة مع مدرب</h1>
      <p style={{ color: '#4A6063' }}>اختار المدرب، شوف المواعيد، وادفع. الدخول للجلسة من تطبيق بوصلتي.</p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          load(query);
        }}
        style={{ display: 'flex', gap: 8, margin: '20px 0' }}
      >
        <input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="ابحث بالاسم أو التخصص"
          style={{ flex: 1, padding: 12, borderRadius: 12, border: '1px solid #E5DCCB' }}
        />
        <button type="submit" style={{ padding: '12px 18px', borderRadius: 12, background: '#0E6E75', color: 'white', border: 0 }}>
          بحث
        </button>
      </form>
      {error ? <p>{error}</p> : null}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 16 }}>
        {trainers.map((trainer) => (
          <a key={trainer.id} href={`/trainers/${trainer.id}`} style={{ textDecoration: 'none', color: 'inherit', background: 'white', borderRadius: 16, padding: 16, border: '1px solid #E5DCCB' }}>
            <strong>{trainer.display_name}</strong>
            <div>{trainer.headline}</div>
            <div style={{ marginTop: 8, color: '#0E6E75' }}>
              {trainer.starting_price ? `من ${trainer.starting_price} ${trainer.currency || ''}` : ''}
            </div>
            <div style={{ fontSize: 13, color: '#865407' }}>{trainer.rating_average || 0} ★</div>
          </a>
        ))}
      </div>
    </main>
  );
}
