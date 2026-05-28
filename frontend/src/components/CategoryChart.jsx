import React from 'react';
import { Doughnut, Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend,
  CategoryScale,
  LinearScale,
  BarElement,
} from 'chart.js';

// Register Chart.js components
ChartJS.register(ArcElement, Tooltip, Legend, CategoryScale, LinearScale, BarElement);

// Vibrant color palette for categories
const CATEGORY_COLORS = {
  food: '#ffab40',
  transport: '#42a5f5',
  housing: '#ce93d8',
  utilities: '#4dd0e1',
  healthcare: '#81c784',
  entertainment: '#f48fb1',
  shopping: '#ff8a65',
  education: '#9fa8da',
  travel: '#80cbc4',
  subscriptions: '#bcaaa4',
  groceries: '#aed581',
  personal: '#ffd54f',
  business: '#90a4ae',
  other: '#bdbdbd',
};

const CategoryChart = ({ data, type = 'doughnut' }) => {
  if (!data || data.length === 0) {
    return (
      <div className="empty-state" style={{ padding: '2rem' }}>
        <p style={{ color: 'var(--text-muted)' }}>No data to display</p>
      </div>
    );
  }

  const labels = data.map((item) => item.category.charAt(0).toUpperCase() + item.category.slice(1));
  const amounts = data.map((item) => item.total_amount);
  const colors = data.map((item) => CATEGORY_COLORS[item.category] || '#bdbdbd');

  const chartData = {
    labels,
    datasets: [
      {
        label: 'Spending (₹)',
        data: amounts,
        backgroundColor: colors.map((c) => c + '99'), // Add transparency
        borderColor: colors,
        borderWidth: 2,
        hoverOffset: type === 'doughnut' ? 15 : 0,
        borderRadius: type === 'bar' ? 8 : 0,
      },
    ],
  };

  const commonOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: type === 'doughnut' ? 'right' : 'top',
        labels: {
          color: 'rgba(255,255,255,0.7)',
          font: { family: "'Inter', sans-serif", size: 11 },
          padding: 12,
          usePointStyle: true,
          pointStyleWidth: 10,
        },
      },
      tooltip: {
        backgroundColor: 'rgba(26, 26, 62, 0.95)',
        titleFont: { family: "'Inter', sans-serif", size: 13 },
        bodyFont: { family: "'Inter', sans-serif", size: 12 },
        padding: 12,
        cornerRadius: 8,
        callbacks: {
          label: (context) =>
            ` ₹${context.parsed.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`,
        },
      },
    },
  };

  const doughnutOptions = {
    ...commonOptions,
    cutout: '65%',
  };

  const barOptions = {
    ...commonOptions,
    scales: {
      x: {
        ticks: { color: 'rgba(255,255,255,0.5)', font: { size: 10 } },
        grid: { display: false },
      },
      y: {
        ticks: {
          color: 'rgba(255,255,255,0.5)',
          font: { size: 10 },
          callback: (value) => `₹${value.toLocaleString('en-IN')}`,
        },
        grid: { color: 'rgba(255,255,255,0.05)' },
      },
    },
  };

  return (
    <div style={{ height: '280px', position: 'relative' }}>
      {type === 'doughnut' ? (
        <Doughnut data={chartData} options={doughnutOptions} />
      ) : (
        <Bar data={chartData} options={barOptions} />
      )}
    </div>
  );
};

export default CategoryChart;
