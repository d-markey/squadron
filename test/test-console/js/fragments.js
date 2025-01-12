async function loadFragments() {
    let elements = document.getElementsByTagName('*');
    for (var i = 0; i < elements.length; i++) {
        let element = elements[i], file = element.getAttribute('x-fragment');
        if (file) {
            let res = await fetch(file);
            if (res.status == 200) {
                element.innerHTML = await res.text();
            } else {
                element.innerHTML = `(ERROR: ${res.statusText})`;
            }
        }
    }
}
