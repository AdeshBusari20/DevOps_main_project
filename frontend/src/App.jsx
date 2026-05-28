import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import Navbar from './components/Navbar';
import Dashboard from './components/Dashboard';
import ExpenseForm from './components/ExpenseForm';
import ExpenseList from './components/ExpenseList';

function App() {
  return (
    <Router>
      <div className="app">
        <Navbar />
        <ToastContainer
          position="top-right"
          autoClose={3000}
          hideProgressBar={false}
          newestOnTop
          closeOnClick
          rtl={false}
          pauseOnFocusLoss
          draggable
          pauseOnHover
          theme="dark"
        />
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/add" element={<ExpenseForm />} />
          <Route path="/edit/:id" element={<ExpenseForm />} />
          <Route path="/expenses" element={<ExpenseList />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
