function switchTab(tab){
        document
            .querySelectorAll('.tab')[1]
            .classList.add('active');

        document
            .getElementById('register-page')
            .classList.add('active-page');
    }
}

function showMessage(text, success){

    const msg = document.getElementById('message');

    msg.innerText = text;

    msg.className = success ? 'success' : 'error';
}

function login(){

    const username =
        document.getElementById('login-username').value;

    const password =
        document.getElementById('login-password').value;

    if(username === '' || password === ''){
        showMessage('Vui lòng nhập đầy đủ thông tin.', false);
        return;
    }

    mta.triggerEvent(
        'onLoginSubmit',
        username,
        password
    );
}

function register(){

    const username =
        document.getElementById('register-username').value;

    const password =
        document.getElementById('register-password').value;

    const confirm =
        document.getElementById('register-confirm-password').value;

    if(username === '' || password === ''){
        showMessage('Vui lòng nhập đầy đủ thông tin.', false);
        return;
    }

    if(password !== confirm){
        showMessage('Mật khẩu không khớp.', false);
        return;
    }

    mta.triggerEvent(
        'onRegisterSubmit',
        username,
        password
    );
}