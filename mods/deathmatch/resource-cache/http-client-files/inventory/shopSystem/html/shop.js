let SHOP_ID = null;
let SHOP_NAME = '';
let SHOP_ITEMS = [];
let CART = {};

function renderShop() {
    document.getElementById('shop-title').textContent = SHOP_NAME;
    const itemsDiv = document.getElementById('shop-items');
    itemsDiv.innerHTML = '';
    let cartCount = 0;
    let allSoldOut = true;
    SHOP_ITEMS.forEach(item => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'shop-item';
        const img = document.createElement('img');
        img.src = item.image;
        img.alt = item.name;
        itemDiv.appendChild(img);
        const nameDiv = document.createElement('div');
        nameDiv.className = 'item-name';
        nameDiv.textContent = item.name;
        itemDiv.appendChild(nameDiv);
        const priceDiv = document.createElement('div');
        priceDiv.className = 'item-price';
        priceDiv.textContent = `$${item.price}`;
        itemDiv.appendChild(priceDiv);
        const qtyDiv = document.createElement('div');
        qtyDiv.className = 'item-qty';
        qtyDiv.textContent = `In stock: ${item.quantity}`;
        itemDiv.appendChild(qtyDiv);
        const actionsDiv = document.createElement('div');
        actionsDiv.className = 'item-actions';
        // Add button
        const addBtn = document.createElement('button');
        addBtn.textContent = '+';
        addBtn.disabled = item.quantity < 1;
        addBtn.onclick = () => {
            if (!CART[item.name]) CART[item.name] = 0;
            if (CART[item.name] < item.quantity) {
                CART[item.name]++;
                renderShop();
            }
        };
        actionsDiv.appendChild(addBtn);
        // Remove button
        const removeBtn = document.createElement('button');
        removeBtn.textContent = '-';
        removeBtn.disabled = !CART[item.name];
        removeBtn.onclick = () => {
            if (CART[item.name]) {
                CART[item.name]--;
                if (CART[item.name] <= 0) delete CART[item.name];
                renderShop();
            }
        };
        actionsDiv.appendChild(removeBtn);
        // Cart quantity display
        if (CART[item.name]) {
            const cartQty = document.createElement('span');
            cartQty.textContent = ` x${CART[item.name]}`;
            cartQty.style.margin = '0 6px';
            cartQty.style.color = '#88b853';
            actionsDiv.appendChild(cartQty);
            cartCount += CART[item.name];
        }
        itemDiv.appendChild(actionsDiv);
        if (item.quantity > 0) allSoldOut = false;
        itemsDiv.appendChild(itemDiv);
    });
    // Cart summary
    document.getElementById('cart-summary').textContent = `Cart: ${cartCount} item${cartCount === 1 ? '' : 's'}`;
    // Buy button
    const buyBtn = document.getElementById('buy-btn');
    buyBtn.disabled = cartCount === 0 || allSoldOut;
}

window.setShopData = function(shopID, shopName, itemsArray) {
    SHOP_ID = shopID;
    SHOP_NAME = shopName;
    SHOP_ITEMS = itemsArray;
    CART = {};
    renderShop();
};

document.getElementById('close-btn').onclick = function() {
    if (typeof mta !== 'undefined' && mta.triggerEvent) {
        mta.triggerEvent('shop:close');
    }
};

document.getElementById('buy-btn').onclick = function() {
    if (typeof mta !== 'undefined' && mta.triggerEvent) {
        mta.triggerEvent('shop:buyItems', SHOP_ID, JSON.stringify(CART));
    }
};

// Listen for shop:closeUI event from Lua to close the UI after successful purchase
window.addEventListener('message', function(event) {
    if (event.data && event.data.type === 'shop:closeUI') {
        document.getElementById('close-btn').click();
    }
});

window.showShopMessage = function(msg, type) {
    let toast = document.getElementById('shop-toast');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'shop-toast';
        toast.style.position = 'fixed';
        toast.style.top = '32px';
        toast.style.left = '50%';
        toast.style.transform = 'translateX(-50%)';
        toast.style.zIndex = '9999';
        toast.style.padding = '18px 36px';
        toast.style.borderRadius = '12px';
        toast.style.fontSize = '1.2rem';
        toast.style.fontWeight = 'bold';
        toast.style.boxShadow = '0 2px 16px #0005';
        toast.style.transition = 'opacity 0.3s';
        document.body.appendChild(toast);
    }
    toast.style.opacity = '1';
    toast.textContent = msg;
    if (type === 'success') {
        toast.style.background = 'linear-gradient(90deg,#2ecc40,#27ae60)';
        toast.style.color = '#fff';
    } else if (type === 'error') {
        toast.style.background = 'linear-gradient(90deg,#e74c3c,#c0392b)';
        toast.style.color = '#fff';
    } else {
        toast.style.background = 'linear-gradient(90deg,#3498db,#2980b9)';
        toast.style.color = '#fff';
    }
    clearTimeout(window._shopToastTimeout);
    window._shopToastTimeout = setTimeout(() => {
        toast.style.opacity = '0';
    }, 3000);
}; 