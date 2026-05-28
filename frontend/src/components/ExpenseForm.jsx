import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { toast } from 'react-toastify';
import { FiSave, FiX } from 'react-icons/fi';
import { expenseApi, categoryApi } from '../services/api';

const INITIAL_STATE = {
  title: '',
  amount: '',
  category: '',
  date: new Date().toISOString().split('T')[0],
  description: '',
};

const ExpenseForm = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditing = Boolean(id);

  const [formData, setFormData] = useState(INITIAL_STATE);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    fetchCategories();
    if (isEditing) {
      fetchExpense();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const fetchCategories = async () => {
    try {
      const response = await categoryApi.getAll();
      setCategories(response.data.categories || []);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const fetchExpense = async () => {
    try {
      setLoading(true);
      const response = await expenseApi.getById(id);
      const expense = response.data;
      setFormData({
        title: expense.title,
        amount: expense.amount.toString(),
        category: expense.category,
        date: expense.date,
        description: expense.description || '',
      });
    } catch (error) {
      toast.error('Failed to load expense');
      navigate('/expenses');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validation
    if (!formData.title.trim()) {
      toast.error('Title is required');
      return;
    }
    if (!formData.amount || parseFloat(formData.amount) <= 0) {
      toast.error('Amount must be greater than 0');
      return;
    }

    try {
      setSubmitting(true);
      const payload = {
        title: formData.title.trim(),
        amount: parseFloat(formData.amount),
        category: formData.category || null, // null = AI auto-categorize
        date: formData.date,
        description: formData.description.trim() || null,
      };

      if (isEditing) {
        await expenseApi.update(id, payload);
        toast.success('Expense updated successfully! ✅');
      } else {
        await expenseApi.create(payload);
        toast.success('Expense added successfully! 🎉');
      }
      navigate('/expenses');
    } catch (error) {
      toast.error(
        error.response?.data?.detail || 'Failed to save expense'
      );
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div className="expense-form-container" id="expense-form-page">
      <h2>{isEditing ? '✏️ Edit Expense' : '➕ Add New Expense'}</h2>
      <div className="glass-card">
        <form onSubmit={handleSubmit}>
          {/* Title */}
          <div className="form-group">
            <label htmlFor="title">Expense Title</label>
            <input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="e.g., Uber ride to office"
              required
              autoFocus
            />
          </div>

          {/* Amount + Date Row */}
          <div className="form-row">
            <div className="form-group">
              <label htmlFor="amount">Amount (₹)</label>
              <input
                type="number"
                id="amount"
                name="amount"
                value={formData.amount}
                onChange={handleChange}
                placeholder="0.00"
                min="0.01"
                step="0.01"
                required
              />
            </div>
            <div className="form-group">
              <label htmlFor="date">Date</label>
              <input
                type="date"
                id="date"
                name="date"
                value={formData.date}
                onChange={handleChange}
                required
              />
            </div>
          </div>

          {/* Category */}
          <div className="form-group">
            <label htmlFor="category">
              Category
              <span style={{ color: 'var(--text-muted)', fontWeight: 400, textTransform: 'none', letterSpacing: 0 }}>
                {' '}— leave empty for AI auto-categorization
              </span>
            </label>
            <select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
            >
              <option value="">🤖 Auto-categorize with AI</option>
              {categories.map((cat) => (
                <option key={cat.value} value={cat.value}>
                  {cat.label}
                </option>
              ))}
            </select>
          </div>

          {/* Description */}
          <div className="form-group">
            <label htmlFor="description">Description (Optional)</label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              placeholder="Add details about this expense..."
              rows={3}
            />
          </div>

          {/* Action Buttons */}
          <div style={{ display: 'flex', gap: '1rem', marginTop: '1.5rem' }}>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={submitting}
              id="submit-expense-btn"
              style={{ flex: 1 }}
            >
              <FiSave />
              {submitting ? 'Saving...' : isEditing ? 'Update Expense' : 'Add Expense'}
            </button>
            <button
              type="button"
              className="btn btn-outline"
              onClick={() => navigate(-1)}
              id="cancel-btn"
            >
              <FiX />
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ExpenseForm;
