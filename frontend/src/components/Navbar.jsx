import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { FiPlusCircle, FiList, FiHome } from 'react-icons/fi';

const Navbar = () => {
  const location = useLocation();

  const isActive = (path) => location.pathname === path ? 'active' : '';

  return (
    <nav className="navbar" id="main-navbar">
      <Link to="/" className="navbar-brand">
        <span className="brand-icon">💰</span>
        AI Expense Tracker
      </Link>
      <ul className="navbar-links">
        <li>
          <Link to="/" className={isActive('/')} id="nav-dashboard">
            <FiHome style={{ marginRight: '4px', verticalAlign: 'middle' }} />
            Dashboard
          </Link>
        </li>
        <li>
          <Link to="/add" className={isActive('/add')} id="nav-add-expense">
            <FiPlusCircle style={{ marginRight: '4px', verticalAlign: 'middle' }} />
            Add Expense
          </Link>
        </li>
        <li>
          <Link to="/expenses" className={isActive('/expenses')} id="nav-expenses">
            <FiList style={{ marginRight: '4px', verticalAlign: 'middle' }} />
            All Expenses
          </Link>
        </li>
      </ul>
    </nav>
  );
};

export default Navbar;
