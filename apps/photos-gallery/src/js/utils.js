const Utils = {
  formatBytes(bytes, decimals = 1) {
    if (!bytes || bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  },

  formatDate(timestamp) {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;
  },

  formatDateRange(timestamps) {
    if (!timestamps || timestamps.length === 0) return '';
    const sorted = [...timestamps].sort((a, b) => a - b);
    const earliest = new Date(sorted[0]);
    const latest = new Date(sorted[sorted.length - 1]);

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    if (earliest.getFullYear() === latest.getFullYear() && earliest.getMonth() === latest.getMonth() && earliest.getDate() === latest.getDate()) {
      return `${earliest.getDate()} ${months[earliest.getMonth()]} ${earliest.getFullYear()}`;
    }

    if (earliest.getFullYear() === latest.getFullYear() && earliest.getMonth() === latest.getMonth()) {
      return `${earliest.getDate()} - ${latest.getDate()} ${months[latest.getMonth()]} ${latest.getFullYear()}`;
    }

    return `${earliest.getDate()} ${months[earliest.getMonth()]} ${earliest.getFullYear()} - ${latest.getDate()} ${months[latest.getMonth()]} ${latest.getFullYear()}`;
  },

  debounce(func, wait = 150) {
    let timeout;
    return function (...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  },

  showToast(message, duration = 2600) {
    let toast = document.getElementById('fluent-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'fluent-toast';
      toast.className = 'fluent-toast';
      document.body.appendChild(toast);
    }
    toast.innerHTML = `
      <div class="fluent-toast-icon">
        <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
        </svg>
      </div>
      <span class="fluent-toast-message">${message}</span>
    `;
    toast.classList.add('show');
    clearTimeout(toast._timer);
    toast._timer = setTimeout(() => {
      toast.classList.remove('show');
    }, duration);
  }
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = Utils;
}
