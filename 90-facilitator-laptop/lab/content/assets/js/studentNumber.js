function setStudentNumber() {
    var user = document.getElementById("studentNumberForm").value;
    localStorage.setItem("studentNumber", user);
    updateHTML();
    toggleStudentNumberInputVisibility();
}
function getStudentNumber() {
    return localStorage.getItem("studentNumber");
}

function updateHTML() {
    const name = getStudentNumber();

    document.getElementById("greeting").innerHTML = "Welcome, Student" + name;

    const studentIdElements = document.getElementsByClassName("studentId");
    Array.prototype.forEach.call(studentIdElements, function(studentIdElement) {
        studentIdElement.innerHTML = name;
    });
}

window.onload = function toggleStudentNumberInputVisibility() {
    var x = getStudentNumber();
    var y = document.getElementById("studentNumberElement");
    if ( x ) {
        y.style.display = "none";
        updateHTML();
    } else {
        y.style.display = "block";
    }
};