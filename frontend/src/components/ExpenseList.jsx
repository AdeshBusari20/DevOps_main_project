import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { toast } from 'react-toastify';
import { FiEdit2, FiTrash2, FiPlus } from 'react-icons/fi';
import { expenseApi } from '../services/api';

const ExpenseList = () => {
  const [expenses, setExpenses] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [categoryFilter, setCategoryFilter] = useState('');
  const [sortBy, setSortBy] = useState('date');
  const [sortOrder, setSortOrder] = useState('desc');
  const [page, setPage] = useState(0);
  const limit = 15;

  useEffect(() => {
    fetchExpenses();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [categoryFilter, sortBy, sortOrder, page]);

  const fetchExpenses = async () => {
    try {
      setLoading(true);
      const params = {
        skip: page * limit,
        limit,
        sort_by: sortBy,
        sort_order: sortOrder,
      };
      if (categoryFilter) params.category = categoryFilter;

      const response = await expenseApi.getAll(params);
      setExpenses(response.data.expenses || []);
      setTotal(response.data.total || 0);
    } catch (error) {
      console.error('Error fetching expenses:', error);
      toast.error('Failed to load expenses');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Delete "${title}"? This cannot be undone.`)) return;

    try {
      await expenseApi.delete(id);
      toast.success('Expense deleted 🗑️');
      fetchExpenses();
    } catch (error) {
      toast.error('Failed to delete expense');
    }
  };

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="expense-list-container" id="expense-list-page">
      {/* Header */}
      <div className="expense-list-header">
        <h2>📋 All Expenses ({total})</h2>
        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
          <div className="expense-filters">
            <select
              value={categoryFilter}
              onChange={(e) => { setCategoryFilter(e.target.value); setPage(0); }}
              id="category-filter"
            >
              <option value="">All Categories</option>
              <option value="food">Food</option>
              <option value="transport">Transport</option>
              <option value="housing">Housing</option>
              <option value="utilities">Utilities</option>
              <option value="healthcare">Healthcare</option>
              <option value="entertainment">Entertainment</option>
              <option value="shopping">Shopping</option>
              <option value="education">Education</option>
              <option value="travel">Travel</option>
              <option value="subscriptions">Subscriptions</option>
              <option value="groceries">Groceries</option>
              <option value="personal">Personal</option>
              <option value="business">Business</option>
              <option value="other">Other</option>
            </select>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              id="sort-by"
            >
              <option value="date">Sort by Date</option>
              <option value="amount">Sort by Amount</option>
              <option value="title">Sort by Title</option>
            </select>
            <select
              value={sortOrder}
              onChange={(e) => setSortOrder(e.target.value)}
              id="sort-order"
            >
              <option value="desc">Descending</option>
              <option value="asc">Ascending</option>
            </select>
          </div>
          <Link to="/add" className="btn btn-primary btn-sm" id="add-expense-link">
            <FiPlus /> Add Expense
          </Link>
        </div>
      </div>

      {/* Table */}
      <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
        {loading ? (
          <div className="loading">
            <div className="spinner"></div>
          </div>
        ) : expenses.length > 0 ? (
          <>
            <table className="expense-table">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Amount</th>
                  <th>Category</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {expenses.map((expense, index) => (
                  <tr
                    key={expense.id}
                    style={{ animation: `slideIn 0.3s ease ${index * 0.05}s both` }}
                  >
                    <td>
                      <div>
                        <strong>{expense.title}</strong>
                        {expense.description && (
                          <div style={{ color: 'var(--text-muted)', fontSize: 'var(--font-size-xs)', marginTop: '2px' }}>
                            {expense.description.substring(0, 60)}
                            {expense.description.length > 60 ? '...' : ''}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="amount">
                      ₹{expense.amount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </td>
                    <td>
                      <span className={`category-badge category-${expense.category}`}>
                        {expense.category}
                      </span>
                    </td>
                    <td style={{ color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>
                      {new Date(expense.date).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td>
                      <div className="action-buttons">
                        <Link
                          to={`/edit/${expense.id}`}
                          className="btn btn-outline btn-sm"
                          title="Edit"
                        >
                          <FiEdit2 />
                        </Link>
                        <button
                          className="btn btn-danger btn-sm"
                          onClick={() => handleDelete(expense.id, expense.title)}
                          title="Delete"
                        >
                          <FiTrash2 />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* Pagination */}
            {totalPages > 1 && (
              <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                gap: '1rem',
                padding: '1rem',
                borderTop: '1px solid var(--border-color)',
              }}>
                <button
                  className="btn btn-outline btn-sm"
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  disabled={page === 0}
                >
                  ← Previous
                </button>
                <span style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-size-sm)' }}>
                  Page {page + 1} of {totalPages}
                </span>
                <button
                  className="btn btn-outline btn-sm"
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                >
                  Next →
                </button>
              </div>
            )}
          </>
        ) : (
          <div className="empty-state">
            <div className="empty-icon">📭</div>
            <p>No expenses found</p>
            <Link to="/add" className="btn btn-primary">Add Your First Expense</Link>
          </div>
        )}
      </div>
    </div>
  );
};

export default ExpenseList;
