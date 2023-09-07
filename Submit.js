import ShowTeacher from "./Showteacher";
import SubProject from "./SubProject";
import styles from "./Submit.module.css";

export default function Submit(){
    return(
        <div className={styles.submitPage}>
            <div className={styles.submitBox}>
        <SubProject></SubProject>
        <div className={styles.vertLine}></div>
        <ShowTeacher></ShowTeacher>
        
        </div>
        </div>
        
    )
}