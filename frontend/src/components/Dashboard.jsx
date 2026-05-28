import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiDollarSign, FiTrendingUp, FiPieChart, FiCalendar } from 'react-icons/fi';
import { expenseApi } from '../services/api';
import CategoryChart from './CategoryChart';

const Dashboard = () => {
  const [analytics, setAnalytics] = useState(null);
  const [recentExpenses, setRecentExpenses] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const [analyticsRes, expensesRes] = await Promise.all([
        expenseApi.getAnalytics(),
        expenseApi.getAll({ limit: 5, sort_by: 'date', sort_order: 'desc' }),
      ]);
      setAnalytics(analyticsRes.data);
      setRecentExpenses(expensesRes.data.expenses || []);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      // Set defaults on error so UI still renders
      setAnalytics({
        total_expenses: 0,
        total_count: 0,
        average_expense: 0,
        category_breakdown: [],
      });
      setRecentExpenses([]);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  const stats = [
    {
      icon: <FiDollarSign />,
      value: `₹${(analytics?.total_expenses || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`,
      label: 'Total Expenses',
    },
    {
      icon: <FiTrendingUp />,
      value: analytics?.total_count || 0,
      label: 'Total Transactions',
    },
    {
      icon: <FiPieChart />,
      value: `₹${(analytics?.average_expense || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`,
      label: 'Average Expense',
    },
    {
      icon: <FiCalendar />,
      value: analytics?.category_breakdown?.length || 0,
      label: 'Categories Used',
    },
  ];

  return (
    <div className="dashboard" id="dashboard-page">
      {/* Header */}
      <div className="dashboard-header">
        <h1>📊 Dashboard</h1>
        <p>Your financial overview at a glance</p>
      </div>

      {/* Stats Grid */}
      <div className="stats-grid">
        {stats.map((stat, index) => (
          <div key={index} className="glass-card stat-card" style={{ animationDelay: `${index * 0.1}s` }}>
            <div className="stat-icon">{stat.icon}</div>
            <div className="stat-value">{stat.value}</div>
            <div className="stat-label">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Charts Section */}
      <div className="charts-section">
        <div className="glass-card chart-card">
          <h3>📈 Spending by Category</h3>
          <CategoryChart data={analytics?.category_breakdown || []} type="doughnut" />
        </div>
        <div className="glass-card chart-card">
          <h3>📊 Category Distribution</h3>
          <CategoryChart data={analytics?.category_breakdown || []} type="bar" />
        </div>
      </div>

      {/* Recent Expenses */}
      <div className="glass-card">
        <div className="expense-list-header">
          <h3>🕐 Recent Expenses</h3>
          <Link to="/expenses" className="btn btn-outline btn-sm">
            View All →
          </Link>
        </div>
        {recentExpenses.length > 0 ? (
          <table className="expense-table">
            <thead>
              <tr>
                <th>Title</th>
                <th>Amount</th>
                <th>Category</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {recentExpenses.map((expense) => (
                <tr key={expense.id}>
                  <td>{expense.title}</td>
                  <td className="amount">₹{expense.amount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                  <td>
                    <span className={`category-badge category-${expense.category}`}>
                      {expense.category}
                    </span>
                  </td>
                  <td style={{ color: 'var(--text-secondary)' }}>
                    {new Date(expense.date).toLocaleDateString('en-IN')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="empty-state">
            <div className="empty-icon">💸</div>
            <p>No expenses yet. Start tracking!</p>
            <Link to="/add" className="btn btn-primary">Add Your First Expense</Link>
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard;
